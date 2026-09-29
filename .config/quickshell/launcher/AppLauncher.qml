import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import "Fuzzy.js" as Fuzzy

Scope {
    id: root

    property string terminal: "konsole"
    readonly property int visibleRows: 8

    property string query: ""
    property int sel: 0
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var results: rank(query.trim(), apps)
    readonly property int appMatches: results.filter(r => r.kind === "app").length

    signal shown()

    function close() { overlay.open = false }

    function appIds(entry: var): var {
        return [entry.startupClass, entry.id, entry.command[0]?.split("/").pop()].filter(k => k).map(k => k.toLowerCase());
    }

    function windowFor(entry: var): var {
        const ids = appIds(entry);
        return ToplevelManager.toplevels.values.find(t => ids.includes(t.appId.toLowerCase())) ?? null;
    }

    function rank(q: string, list: var): var {
        const boost = id => Math.min(40, 12 * Math.log2(1 + usage.frecency(id)));
        const open = new Set(ToplevelManager.toplevels.values.map(t => t.appId.toLowerCase()));
        const rows = [];
        for (const entry of list) {
            const detail = entry.genericName || entry.comment;
            const running = appIds(entry).some(id => open.has(id));
            if (q === "") {
                rows.push({ kind: "app", entry, name: entry.name, detail, running, positions: [], score: usage.frecency(entry.id) });
                continue;
            }
            const byName = Fuzzy.match(q, entry.name, true);
            const others = [entry.genericName, entry.id, entry.command[0]?.split("/").pop(), ...entry.keywords]
                .map(s => Fuzzy.match(q, s, false))
                .filter(m => m !== null)
                .map(m => m.score * 0.6);
            const best = Math.max(byName?.score ?? 0, ...others);
            if (best <= 0) continue;
            rows.push({ kind: "app", entry, name: entry.name, detail, running, positions: byName?.positions ?? [], score: best + boost(entry.id) });
        }
        if (q !== "") {
            for (const entry of list) {
                for (const action of entry.actions) {
                    const name = `${entry.name}: ${action.name}`;
                    const m = Fuzzy.match(q, name, true);
                    if (m !== null && m.score > 0)
                        rows.push({ kind: "action", entry, action, name, detail: "", running: false, positions: m.positions, score: m.score * 0.9 + boost(entry.id) });
                }
            }
        }
        rows.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name));
        if (q !== "") rows.push({ kind: "shell", command: q });
        return rows;
    }

    function move(delta: int) {
        sel = Math.max(0, Math.min(results.length - 1, sel + delta));
        list.positionViewAtIndex(sel, ListView.Contain);
    }

    function launch(r: var, switchTo: bool) {
        if (!r) return;
        overlay.open = false;
        if (r.kind === "shell") {
            Quickshell.execDetached(["sh", "-c", `cd && ${r.command}`]);
            return;
        }
        usage.bump(r.entry.id);
        if (r.kind === "action") {
            r.action.execute();
            return;
        }
        const win = windowFor(r.entry);
        if (switchTo && win !== null) {
            win.activate();
            return;
        }
        if (r.entry.runInTerminal)
            Quickshell.execDetached([terminal, "-e", ...r.entry.command]);
        else
            r.entry.execute();
    }

    function handleKey(event: var) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (event.key === Qt.Key_Escape) overlay.open = false;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) launch(results[sel], event.modifiers & Qt.ShiftModifier);
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)) move(1);
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)) move(-1);
        else if (event.key === Qt.Key_PageDown) move(visibleRows);
        else if (event.key === Qt.Key_PageUp) move(-visibleRows);
        else return;
        event.accepted = true;
    }

    Usage {
        id: usage
        name: "launcher"
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { overlay.toggle() }
        function open(): void { if (!overlay.open) overlay.show() }
        function close(): void { overlay.open = false }
    }

    Overlay {
        id: overlay
        namespace: "qs-launcher"
        frameWidth: 640
        onShown: {
            prompt.reset();
            root.sel = 0;
            list.positionViewAtBeginning();
            root.shown();
        }

        Prompt {
            id: prompt
            width: parent.width
            cmd: "run"
            placeholder: "search apps, or type a command"
            info: root.query.trim() === "" ? `${root.apps.length}` : `${root.appMatches}/${root.apps.length}`
            onTextChanged: {
                root.query = text;
                root.sel = 0;
                list.positionViewAtBeginning();
            }
            onKeyPressed: event => root.handleKey(event)
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        ListView {
            id: list
            width: parent.width
            height: Math.min(count, root.visibleRows) * 42
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.results

            delegate: AppRow {
                selected: index === root.sel
                onHovered: root.sel = index
                onPicked: root.launch(modelData, false)
            }
        }
    }
}
