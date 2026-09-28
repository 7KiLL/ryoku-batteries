import QtQuick
import Ryoku.PluginKit.Singletons

// Bar glyph: one icon + % per device. Click toggles the panel, never mutates.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var cfg: pluginApi ? pluginApi.pluginSettings : ({})
    readonly property int low: cfg.lowPercent ?? 15
    readonly property bool showPercent: cfg.showPercent ?? true
    readonly property bool hideOffline: cfg.hideOffline ?? false
    readonly property var shown: service ? service.barDevices.filter(d => d.level >= 0 || !hideOffline) : []

    function icon(d) {
        if (d.status === "BATTERY_CHARGING") return "\u{f0084}"; // nf-md battery_charging
        if (d.kind === "mouse") return "\u{f037d}";                // nf-md mouse
        if (d.kind === "headset") return "\u{f02cb}";              // nf-md headphones
        return "\u{f0079}";                                        // nf-md battery
    }

    visible: shown.length > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10 * root.s

        Repeater {
            model: root.shown
            delegate: Row {
                id: dv
                required property var modelData
                readonly property bool online: modelData.level >= 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.icon(dv.modelData)
                    color: !dv.online ? Theme.dim
                         : (dv.modelData.level <= root.low && dv.modelData.status !== "BATTERY_CHARGING") ? Theme.vermDeep
                         : Theme.accent
                    font.family: Theme.mono
                    font.pixelSize: 14 * root.s
                }

                Text {
                    visible: root.showPercent
                    anchors.verticalCenter: parent.verticalCenter
                    text: dv.online ? dv.modelData.level + "%" : "—"
                    color: dv.online ? Theme.bright : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
    }
}
