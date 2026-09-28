pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Polls `headsetcontrol -o json -b` and exposes every device it reports.
// ponytail: headsetcontrol is the only backend; add a per-backend reader here
// (e.g. upower for Bluetooth) when a second device type shows up.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property int pollSec: settings ? (settings.pollSec ?? 60) : 60

    // [{ name, product, status, level, error }]; empty = no headset connected.
    property var devices: []
    property string error: ""
    // The first device is what the glyph shows.
    readonly property var primary: devices.length > 0 ? devices[0] : null

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    Process {
        id: proc
        command: ["headsetcontrol", "-o", "json", "-b"]
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: (code) => {
            try {
                const j = JSON.parse(out.text);
                svc.devices = (j.devices || []).map(d => ({
                    name: d.device || "Headset",
                    product: d.product || "",
                    status: d.battery ? d.battery.status : "BATTERY_UNAVAILABLE",
                    level: d.battery ? d.battery.level : -1,
                    error: d.errors && d.errors.battery ? d.errors.battery : ""
                }));
                svc.error = "";
            } catch (e) {
                svc.devices = [];
                svc.error = err.text.trim() || ("headsetcontrol exited " + code);
            }
        }
    }

    Timer {
        interval: Math.max(10, svc.pollSec) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: svc.refresh()
    }
}
