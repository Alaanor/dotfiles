import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property string name
    property var counts: ({})
    property var prefs: ({})

    function bump(key: string) {
        const next = Object.assign({}, counts);
        next[key] = { n: (counts[key]?.n ?? 0) + 1, t: Math.floor(Date.now() / 1000) };
        counts = next;
        save();
    }

    function setPref(key: string, value) {
        prefs = Object.assign({}, prefs, { [key]: value });
        save();
    }

    function frecency(key: string): real {
        const e = counts[key];
        if (!e) return 0;
        const age = Date.now() / 1000 - e.t;
        return e.n * (age < 3600 ? 4 : age < 86400 ? 2 : age < 604800 ? 1 : 0.5);
    }

    function top(limit: int): list<string> {
        return Object.keys(counts).sort((a, b) => frecency(b) - frecency(a)).slice(0, limit);
    }

    function save() { file.setText(JSON.stringify({ counts, prefs })) }

    FileView {
        id: file
        path: Quickshell.statePath(`${root.name}.json`)
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.counts = j.counts ?? {};
                root.prefs = j.prefs ?? {};
            } catch (e) {}
        }
    }
}
