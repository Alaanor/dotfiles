import QtQuick
import qs
import qs.services

Rectangle {
    id: root
    width: parent.width
    height: 44
    radius: 4
    color: Qt.alpha(Theme.green, 0.06)

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 2

        Connections {
            target: SysStats
            function onCpuHistoryChanged() { canvas.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const h = SysStats.cpuHistory;
            const n = SysStats.historyLength;
            if (h.length < 2) return;
            const step = width / (n - 1);
            const x0 = width - (h.length - 1) * step;
            const y = v => height - 1 - (v / 100) * (height - 2);

            ctx.beginPath();
            ctx.moveTo(x0, y(h[0]));
            for (let i = 1; i < h.length; i++) ctx.lineTo(x0 + i * step, y(h[i]));
            ctx.strokeStyle = Theme.green;
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();

            ctx.lineTo(width, height);
            ctx.lineTo(x0, height);
            ctx.closePath();
            ctx.fillStyle = Qt.alpha(Theme.green, 0.12);
            ctx.fill();
        }
    }
}
