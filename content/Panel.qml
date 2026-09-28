import QtQuick
import Ryoku.PluginKit.Singletons

// Panel: one row per device with a charge bar; the checkbox picks which devices
// the bar glyph shows (at least one stays on). Refresh icon in the header.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 320
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var devices: service ? service.devices : []

    // Only noteworthy states get a line: charging, or why there's no reading.
    function statusText(d) {
        if (d.level < 0) return d.error || "Unavailable (device off?)";
        return d.status === "BATTERY_CHARGING" ? "Charging" : "";
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

        Item {
            width: parent.width
            height: title.implicitHeight

            Text {
                id: title
                text: "Batteries"
                color: Theme.bright
                font.family: Theme.display
                font.pixelSize: 16 * root.s
            }

            Text {
                anchors.right: refreshIcon.left
                anchors.rightMargin: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{f03eb}" // nf-md pencil: edit readers.json
                color: editArea.containsMouse ? Theme.accent : Theme.dim
                font.family: Theme.mono
                font.pixelSize: 15 * root.s

                MouseArea {
                    id: editArea
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.service) { root.service.editConfig(); root.pluginApi.closePanel(); }
                }
            }

            Text {
                id: refreshIcon
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{f0450}" // nf-md refresh
                color: refreshArea.containsMouse ? Theme.accent : Theme.dim
                opacity: root.service && root.service.busy ? 0.4 : 1
                font.family: Theme.mono
                font.pixelSize: 15 * root.s

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.service) root.service.refresh()
                }
            }
        }

        Text {
            visible: root.devices.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            text: "No devices found."
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

                readonly property bool onBar: root.service ? !root.service.barHidden.includes(modelData.key) : true

                Row {
                    width: parent.width
                    spacing: 8 * root.s

                    // Show-on-bar checkbox.
                    Rectangle {
                        id: box
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14 * root.s
                        height: width
                        radius: 3 * root.s
                        color: dv.onBar ? Theme.accent : "transparent"
                        border.width: 1
                        border.color: dv.onBar ? Theme.accent : Theme.dim

                        Text {
                            anchors.centerIn: parent
                            visible: dv.onBar
                            text: "\u{f012c}" // nf-md check
                            color: Theme.cardBot
                            font.family: Theme.mono
                            font.pixelSize: 11 * root.s
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4 * root.s
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.service) root.service.setOnBar(dv.modelData.key, !dv.onBar)
                        }
                    }

                    Text {
                        width: parent.width - pct.implicitWidth - box.width - 2 * parent.spacing
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

                Item {
                    width: parent.width
                    height: 4 * root.s
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.dim
                        opacity: 0.35
                    }
                    Rectangle {
                        width: parent.width * Math.max(0, dv.modelData.level) / 100
                        height: parent.height
                        radius: height / 2
                        color: Theme.accent
                    }
                }

                Text {
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.statusText(dv.modelData)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
            }
        }
    }
}
