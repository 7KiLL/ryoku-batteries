pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Runs bin/batteries (which runs every reader script, see README) on a timer
// and keeps which devices the bar shows in <stateDir>/bar.json.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property int pollSec: settings ? (settings.pollSec ?? 60) : 60

    // [{ key, reader, product, kind, status, level, error }]
    property var devices: []
    readonly property bool busy: proc.running

    // Keys the user unticked in the panel.
    property var barHidden: []
    readonly property var barDevices: {
        const shown = svc.devices.filter(d => !svc.barHidden.includes(d.key));
        return shown.length > 0 ? shown : svc.devices; // never an empty bar
    }

    function setOnBar(key, on) {
        const hidden = svc.barHidden.filter(k => k !== key);
        if (!on) hidden.push(key);
        if (svc.devices.every(d => hidden.includes(d.key))) return; // at least one stays on
        svc.barHidden = hidden;
        barFile.setText(JSON.stringify({ hidden: hidden }));
    }

    function refresh() {
        if (svc.pluginApi && !proc.running) proc.running = true; // a slow poll never stacks up
    }

    onPluginApiChanged: refresh()

    Process {
        id: proc
        command: [svc.pluginApi ? svc.pluginApi.pluginDir + "/bin/batteries" : "true"]
        environment: ({ BATTERIES_STATE: svc.pluginApi ? svc.pluginApi.stateDir : "" })
        stdout: StdioCollector { id: out }
        onExited: {
            try { svc.devices = JSON.parse(out.text).devices || []; } catch (e) {}
        }
    }

    FileView {
        id: barFile
        path: svc.pluginApi ? svc.pluginApi.stateDir + "/bar.json" : ""
        onLoaded: {
            try { svc.barHidden = JSON.parse(barFile.text()).hidden || []; } catch (e) {}
        }
    }

    Timer {
        interval: Math.max(10, svc.pollSec) * 1000
        running: true
        repeat: true
        onTriggered: svc.refresh()
    }
}
