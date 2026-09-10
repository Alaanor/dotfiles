pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property list<string> coins: ["BTC", "ETH", "ICP"]
    readonly property string currency: "CHF"
    property var rates: ({})

    function rate(code: string): string {
        const r = rates[code];
        return r === undefined ? "…" : r.toFixed(2);
    }

    FileView {
        id: keyFile
        path: Quickshell.env("HOME") + "/.secret/livecoinwatch"
        blockLoading: true
    }

    function fetch(code: string) {
        const key = keyFile.text().trim();
        if (key === "") return;
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "https://api.livecoinwatch.com/coins/single");
        xhr.setRequestHeader("content-type", "application/json");
        xhr.setRequestHeader("x-api-key", key);
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return;
            try {
                const r = JSON.parse(xhr.responseText).rate;
                if (typeof r === "number") {
                    const next = Object.assign({}, rates);
                    next[code] = r;
                    rates = next;
                }
            } catch (e) {}
        };
        xhr.send(JSON.stringify({ currency, code, meta: false }));
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.coins.forEach(c => root.fetch(c))
    }
}
