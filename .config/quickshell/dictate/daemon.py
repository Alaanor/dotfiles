"""Push-to-talk dictation daemon: records the mic with pw-record and transcribes with
MAI-Transcribe-2 over OpenRouter when ~/.config/dictate/openrouter.key exists, local Parakeet otherwise or on failure.

Line protocol on $XDG_RUNTIME_DIR/dictate.sock.
  client -> daemon: start | stop | cancel
  daemon -> client: ready | rec | level <0..1> | busy | text <json string> | empty | error <msg>
"""

import asyncio
import base64
import io
import json
import math
import os
import time
import urllib.request
import wave
from pathlib import Path

import numpy as np
import onnx_asr

RATE = 16_000
LEVEL_CHUNK = RATE // 20 * 2
MAX_SECONDS = 180
MIN_SECONDS = 0.3
SPEECH_DB = -42
PHRASES = Path(__file__).with_name("phrases.txt")
KEY_FILE = Path.home() / ".config/dictate/openrouter.key"
OPENROUTER_KEY = KEY_FILE.read_text().strip() if KEY_FILE.exists() else ""
SOCK = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "dictate.sock"


def wav_bytes(audio: np.ndarray) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(audio, -1, 1) * 32767).astype("<i2").tobytes())
    return buf.getvalue()


def transcribe_openrouter(audio: np.ndarray) -> str:
    body = {
        "model": "microsoft/mai-transcribe-2",
        "input_audio": {"data": base64.b64encode(wav_bytes(audio)).decode(), "format": "wav"},
        "language": "en",
    }
    phrases = [l.strip() for l in PHRASES.read_text().splitlines() if l.strip()] if PHRASES.exists() else []
    if phrases:
        body["provider"] = {"options": {"azure": {"phraseList": {"phrases": phrases}}}}
    req = urllib.request.Request(
        "https://openrouter.ai/api/v1/audio/transcriptions",
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {OPENROUTER_KEY}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)["text"]


class Daemon:
    def __init__(self):
        self.model = None
        self.clients: set[asyncio.StreamWriter] = set()
        self.proc: asyncio.subprocess.Process | None = None
        self.reader_task: asyncio.Task | None = None
        self.chunks: list[bytes] = []
        self.started = 0.0
        self.busy = False
        self.peak_db = -100.0

    def send(self, line: str):
        for w in list(self.clients):
            try:
                w.write((line + "\n").encode())
            except Exception:
                self.clients.discard(w)

    async def start(self):
        if self.busy:
            return
        if self.proc is not None:
            await self.stop()
            return
        self.chunks = []
        self.peak_db = -100.0
        self.started = time.monotonic()
        self.proc = await asyncio.create_subprocess_exec(
            "pw-record", "--raw", "--rate", str(RATE), "--channels", "1", "--format", "s16", "-",
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL,
        )
        self.reader_task = asyncio.create_task(self.read_audio(self.proc))
        self.send("rec")

    async def read_audio(self, proc):
        buf = b""
        while chunk := await proc.stdout.read(4096):
            self.chunks.append(chunk)
            buf += chunk
            while len(buf) >= LEVEL_CHUNK:
                frame = np.frombuffer(buf[:LEVEL_CHUNK], dtype=np.int16).astype(np.float32) / 32768
                buf = buf[LEVEL_CHUNK:]
                rms = float(np.sqrt(np.mean(frame * frame)))
                db = 20 * math.log10(max(rms, 1e-5))
                self.peak_db = max(self.peak_db, db)
                self.send(f"level {min(1.0, max(0.0, (db + 55) / 45)):.3f}")
            if time.monotonic() - self.started > MAX_SECONDS:
                asyncio.create_task(self.stop())
                return

    async def end_recording(self) -> bytes:
        proc, self.proc = self.proc, None
        if proc is None:
            return b""
        proc.terminate()
        await proc.wait()
        if self.reader_task is not None:
            await self.reader_task
        return b"".join(self.chunks)

    async def stop(self):
        if self.proc is None:
            return
        pcm = await self.end_recording()
        audio = np.frombuffer(pcm[: len(pcm) // 2 * 2], dtype=np.int16).astype(np.float32) / 32768
        if len(audio) < RATE * MIN_SECONDS or self.peak_db < SPEECH_DB:
            self.send("empty")
            return
        self.busy = True
        self.send("busy")
        try:
            text = await asyncio.to_thread(self.transcribe, audio)
            text = text.strip()
            self.send(f"text {json.dumps(text)}" if text else "empty")
        except Exception as e:
            self.send(f"error {e}")
        finally:
            self.busy = False

    def transcribe(self, audio: np.ndarray) -> str:
        if OPENROUTER_KEY:
            try:
                return transcribe_openrouter(audio)
            except Exception as e:
                print(f"openrouter failed, using parakeet: {e}", flush=True)
        if self.model is None:
            self.model = onnx_asr.load_model("nemo-parakeet-tdt-0.6b-v2", quantization="int8")
        return self.model.recognize(audio, sample_rate=RATE)

    async def cancel(self):
        await self.end_recording()
        self.send("empty")

    async def handle(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        self.clients.add(writer)
        writer.write(b"ready\n")
        try:
            while line := await reader.readline():
                cmd = line.decode().strip()
                if cmd == "start":
                    await self.start()
                elif cmd == "stop":
                    await self.stop()
                elif cmd == "cancel":
                    await self.cancel()
        finally:
            self.clients.discard(writer)
            writer.close()


async def main():
    daemon = Daemon()
    SOCK.unlink(missing_ok=True)
    server = await asyncio.start_unix_server(daemon.handle, path=str(SOCK))
    print(f"listening on {SOCK} ({'openrouter' if OPENROUTER_KEY else 'parakeet'})", flush=True)
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(main())
