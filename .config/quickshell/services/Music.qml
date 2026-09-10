pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string title: (player?.trackTitle ?? "") === "" ? "Nothing playing" : player.trackTitle
    readonly property string cover: (player?.trackArtUrl ?? "").replace("open.spotify.com", "i.scdn.co")

    function toggle() { player?.togglePlaying() }
    function next() { player?.next() }
    function previous() { player?.previous() }
}
