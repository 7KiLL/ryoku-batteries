pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Runs `bin/batteries <config> <stateDir>` on a timer (it runs the readers from
// readers.json, see README) and keeps which devices the bar shows in
// <stateDir>/bar.json.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    // Hub > Add-ons stores int settings as strings; Number() covers both surfaces.
    readonly property int pollSec: Number(settings ? (settings.pollSec ?? 60) : 60) || 60
    readonly property string configPath: {
        const p = String(settings ? (settings.configPath || "") : "") || "~/.config/ryoku-batteries/readers.json";
        return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p;
    }

    // [{ key, reader, product, kind, icon, status, level, error }]
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

    // Creates readers.json from the template if missing, then opens it.
    function editConfig() {
        if (svc.pluginApi) editProc.running = true;
    }

    onPluginApiChanged: refresh()
    onConfigPathChanged: refresh()

    Process {
        id: proc
        command: svc.pluginApi ? [svc.pluginApi.pluginDir + "/bin/batteries", svc.configPath, svc.pluginApi.stateDir] : ["true"]
        stdout: StdioCollector { id: out }
        onExited: {
            try { svc.devices = JSON.parse(out.text).devices || []; } catch (e) {}
        }
    }

    Process {
        id: editProc
        command: svc.pluginApi ? [svc.pluginApi.pluginDir + "/bin/batteries", "--edit", svc.configPath] : ["true"]
    }

    // Saving readers.json applies it right away.
    FileView {
        path: svc.configPath
        watchChanges: true
        printErrors: false // absent until created
        onFileChanged: svc.refresh()
    }

    FileView {
        id: barFile
        path: svc.pluginApi ? svc.pluginApi.stateDir + "/bar.json" : ""
        printErrors: false // absent until the first checkbox click
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
