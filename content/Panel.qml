import QtQuick
import Ryoku.PluginKit.Singletons

// Panel: one row per device headsetcontrol reports, plus a manual refresh.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 320
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var devices: service ? service.devices : []

    function statusText(d) {
        if (d.level < 0) return d.error || "Unavailable (headset off?)";
        return d.status === "BATTERY_CHARGING" ? "Charging" : "Discharging";
    }

    // Refresh on open so the number is fresh.
    onActiveChanged: if (active && service) service.refresh()

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 10 * root.s

        Text {
            text: "Headset"
            color: Theme.bright
            font.family: Theme.display
            font.pixelSize: 16 * root.s
        }

        Text {
            visible: root.devices.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            text: root.service && root.service.error ? root.service.error : "No supported headset found."
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 13 * root.s
        }

        Repeater {
            model: root.devices
            delegate: Column {
                id: dv
                required property var modelData
                width: col.width
                spacing: 4 * root.s

                Row {
                    width: parent.width
                    Text {
                        width: parent.width - pct.implicitWidth
                        text: dv.modelData.product || dv.modelData.name
                        elide: Text.ElideRight
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                    }
                    Text {
                        id: pct
                        text: dv.modelData.level >= 0 ? dv.modelData.level + "%" : "—"
                        color: Theme.accent
                        font.family: Theme.mono
                        font.pixelSize: 13 * root.s
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 4 * root.s
                    radius: height / 2
                    color: Theme.dim
                    opacity: 0.35
                    Rectangle {
                        width: parent.width * Math.max(0, dv.modelData.level) / 100
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }

                Text {
                    text: root.statusText(dv.modelData)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
            }
        }

        Rectangle {
            width: refreshLabel.implicitWidth + 24 * root.s
            height: refreshLabel.implicitHeight + 12 * root.s
            radius: Theme.radius
            color: refreshArea.pressed ? Theme.vermDeep : Theme.accent

            Text {
                id: refreshLabel
                anchors.centerIn: parent
                text: "REFRESH"
                color: Theme.cardBot
                font.family: Theme.font
                font.pixelSize: 12 * root.s
            }

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                onClicked: if (root.service) root.service.refresh()
            }
        }
    }
}
