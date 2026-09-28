import QtQuick
import Ryoku.PluginKit.Singletons

// Bar glyph: headphone mark + battery %. Click toggles the panel, never mutates.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var dev: service ? service.primary : null
    readonly property bool online: dev !== null && dev.level >= 0
    readonly property bool charging: online && dev.status === "BATTERY_CHARGING"
    readonly property int low: pluginApi ? (pluginApi.pluginSettings.lowPercent ?? 15) : 15
    readonly property bool showPercent: pluginApi ? (pluginApi.pluginSettings.showPercent ?? true) : true

    // Hide entirely when no headset is plugged in, if the user asked for that.
    readonly property bool hideOffline: pluginApi ? (pluginApi.pluginSettings.hideOffline ?? false) : false
    visible: online || !hideOffline

    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5 * root.s

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.charging ? "\u{f0084}" : "\u{f02cb}" // nf-md battery_charging / headphones
            color: !root.online ? Theme.dim
                 : (root.dev.level <= root.low && !root.charging) ? Theme.vermDeep
                 : Theme.accent
            font.family: Theme.mono
            font.pixelSize: 14 * root.s
        }

        Text {
            visible: root.showPercent
            anchors.verticalCenter: parent.verticalCenter
            text: root.online ? root.dev.level + "%" : "—"
            color: root.online ? Theme.bright : Theme.dim
            font.family: Theme.font
            font.pixelSize: 13 * root.s
            elide: Text.ElideRight
            width: root.widthBudget > 0 ? Math.min(implicitWidth, root.widthBudget) : implicitWidth
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
    }
}
