pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Polls every reader and merges the devices they report. A reader is any
// command that prints headsetcontrol-shaped JSON: {"devices":[{device, product,
// kind?, battery:{status, level}, errors?:{battery}}]}.
// To add a device type: drop a script in bin/, add a Process below, list its
// command in manifest dependencies/files.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property int pollSec: settings ? (settings.pollSec ?? 60) : 60
    readonly property bool headsetOn: settings ? (settings.headset ?? true) : true
    readonly property bool mouseOn: settings ? (settings.wlmouse ?? true) : true

    // [{ name, product, kind, status, level, error }]
    property var headsets: []
    property var mice: []
    readonly property var devices: (headsetOn ? headsets : []).concat(mouseOn ? mice : [])
    property string error: ""
    readonly property bool busy: hsProc.running || mouseProc.running

    function parse(text, kind) {
        try {
            return (JSON.parse(text).devices || []).map(d => ({
                name: d.device || kind,
                product: d.product || "",
                kind: d.kind || kind,
                status: d.battery ? d.battery.status : "BATTERY_UNAVAILABLE",
                level: d.battery ? d.battery.level : -1,
                error: d.errors && d.errors.battery ? d.errors.battery : ""
            }));
        } catch (e) {
            return [];
        }
    }

    // The host sets pluginApi after load; the first timer tick may miss it.
    onPluginApiChanged: refresh()

    function refresh() {
        if (svc.headsetOn && !hsProc.running) hsProc.running = true;
        if (svc.mouseOn && !mouseProc.running && svc.pluginApi) mouseProc.running = true;
    }

    Process {
        id: hsProc
        command: ["headsetcontrol", "-o", "json", "-b"]
        stdout: StdioCollector { id: hsOut }
        stderr: StdioCollector { id: hsErr }
        onExited: (code) => {
            svc.headsets = svc.parse(hsOut.text, "headset");
            svc.error = svc.headsets.length === 0 && code !== 0 ? (hsErr.text.trim() || "headsetcontrol exited " + code) : "";
        }
    }

    Process {
        id: mouseProc
        command: [svc.pluginApi ? svc.pluginApi.pluginDir + "/bin/wlmouse-battery" : "true"]
        stdout: StdioCollector { id: mouseOut }
        onExited: svc.mice = svc.parse(mouseOut.text, "mouse")
    }

    Timer {
        interval: Math.max(10, svc.pollSec) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: svc.refresh()
    }
}
