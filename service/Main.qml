pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Polls every reader and merges the devices they report.
//
// Reader contract: an executable, run with no arguments and no shell, that
// prints to stdout
//   {"devices":[{"device": str, "product": str, "kind": "headset"|"mouse"|...,
//                "battery": {"status": "BATTERY_CHARGING"|"BATTERY_AVAILABLE"|"BATTERY_UNAVAILABLE",
//                            "level": 0-100 | -1},
//                "errors": {"battery": str}}]}
// (headsetcontrol's JSON shape; every field except battery.level is optional).
// Built-in readers are listed below; the user adds more as absolute paths in
// the "Custom reader scripts" setting.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property int pollSec: settings ? (settings.pollSec ?? 60) : 60

    // A plain string, so saving an unrelated setting (e.g. barHidden) doesn't
    // rebuild the readers: a string property only notifies when it really changes.
    readonly property string readerSpec: {
        const s = svc.settings || {};
        return JSON.stringify([s.headset ?? true, s.wlmouse ?? true, String(s.customReaders ?? ""),
                               svc.pluginApi ? svc.pluginApi.pluginDir : ""]);
    }
    readonly property var readers: {
        const [headset, wlmouse, custom, dir] = JSON.parse(svc.readerSpec);
        const out = [];
        if (headset)
            out.push({ id: "headset", kind: "headset", cmd: ["headsetcontrol", "-o", "json", "-b"] });
        if (wlmouse && dir)
            out.push({ id: "wlmouse", kind: "mouse", cmd: [dir + "/bin/wlmouse-battery"] });
        // ponytail: comma-separated paths in one text setting; a list editor if the bar ever grows one.
        custom.split(",").map(p => p.trim())
            .filter(p => p.startsWith("/"))
            .forEach(p => out.push({ id: p, kind: "device", cmd: [p] }));
        return out;
    }

    // readerId -> [device]; reassigned whole so bindings update.
    property var results: ({})
    property int running: 0
    readonly property bool busy: running > 0

    // [{ key, name, product, kind, status, level, error }], in reader order.
    readonly property var devices: {
        let all = [];
        for (const r of svc.readers) all = all.concat(svc.results[r.id] || []);
        return all;
    }

    // Keys of devices the user unticked for the bar (managed from the panel).
    readonly property var barHidden: String(settings ? (settings.barHidden ?? "") : "").split("|").filter(k => k)
    readonly property var barDevices: {
        const shown = svc.devices.filter(d => !svc.barHidden.includes(d.key));
        return shown.length > 0 ? shown : svc.devices; // never an empty bar
    }

    function setOnBar(key, on) {
        let hidden = svc.barHidden.filter(k => k !== key);
        if (!on) hidden.push(key);
        // At least one device stays on the bar.
        if (svc.devices.every(d => hidden.includes(d.key))) return;
        svc.pluginApi.saveSetting("barHidden", hidden.join("|"));
    }

    function parse(readerId, kind, text, code) {
        try {
            return (JSON.parse(text).devices || []).map(d => ({
                key: readerId + ":" + (d.product || d.device || ""),
                name: d.device || kind,
                product: d.product || "",
                kind: d.kind || kind,
                status: d.battery ? d.battery.status : "BATTERY_UNAVAILABLE",
                level: d.battery && d.battery.level !== undefined ? d.battery.level : -1,
                error: d.errors && d.errors.battery ? d.errors.battery : ""
            }));
        } catch (e) {
            // Surface a broken reader in the panel instead of dropping it silently.
            return [{ key: readerId, name: readerId, product: readerId.split("/").pop(), kind: kind,
                      status: "BATTERY_UNAVAILABLE", level: -1,
                      error: code !== 0 ? "exited " + code : "invalid JSON" }];
        }
    }

    signal refreshRequested()
    function refresh() { svc.refreshRequested(); }

    // Readers that disappear (toggled off / removed) drop their stale devices.
    onReadersChanged: {
        const keep = {};
        for (const r of svc.readers) if (svc.results[r.id]) keep[r.id] = svc.results[r.id];
        svc.results = keep;
        svc.running = 0;
    }

    Repeater {
        model: svc.readers
        delegate: Item {
            id: rd
            required property var modelData

            function run() {
                if (proc.running) return; // a hung reader never stacks up
                proc.running = true;
            }

            Component.onCompleted: rd.run()
            Connections {
                target: svc
                function onRefreshRequested() { rd.run(); }
            }

            Process {
                id: proc
                command: rd.modelData.cmd
                stdout: StdioCollector { id: out }
                // ponytail: busy is cosmetic (refresh icon fade); clamped so a killed reader can't wedge it.
                onRunningChanged: svc.running = Math.max(0, svc.running + (running ? 1 : -1))
                onExited: (code) => {
                    const r = Object.assign({}, svc.results);
                    r[rd.modelData.id] = svc.parse(rd.modelData.id, rd.modelData.kind, out.text, code);
                    svc.results = r;
                }
            }
        }
    }

    Timer {
        interval: Math.max(10, svc.pollSec) * 1000
        running: true
        repeat: true
        onTriggered: svc.refresh()
    }
}
