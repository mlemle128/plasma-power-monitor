import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property string batt: cfg.battPath.replace(/^~/, '"$HOME"')
    readonly property string cmdRaw: batt + " --raw"
    readonly property string cmdFull: batt
    // opens the stock battery applet via its "activate widget N" global shortcut
    readonly property string cmdStock: 'qdbus6 org.kde.kglobalaccel /component/plasmashell '
        + 'org.kde.kglobalaccel.Component.invokeShortcut "activate widget ' + cfg.stockBatteryWidgetId + '"'

    property var batteries: []   // [{name, status, capacity, energy, full, power}]
    property string fullText: ""
    property bool showDetails: false   // middle-click; not remembered

    readonly property real totalEnergy: batteries.reduce((s, b) => s + b.energy, 0)
    readonly property real totalFull: batteries.reduce((s, b) => s + b.full, 0)
    readonly property real totalPower: batteries.reduce((s, b) => s + b.power, 0)
    readonly property int percent: totalFull > 0 ? Math.round(totalEnergy / totalFull * 100) : 0
    readonly property bool charging: batteries.some(b => b.status === "Charging")

    // "INT: 64% · EXT: ▲ 42% · 30.2W"
    readonly property string readout: {
        if (batteries.length === 0)
            return "batt?"
        const parts = batteries.map(b => {
            const label = b.name === "BAT0" ? cfg.internalLabel : cfg.externalLabel
            let arrow = ""
            if (cfg.showArrows && b.status === "Charging")
                arrow = "▲ "
            else if (cfg.showArrows && b.status === "Discharging")
                arrow = "▼ "
            return label + ": " + arrow + b.capacity + "%"
        })
        if (cfg.showPower && totalPower > 0)
            parts.push((totalPower / 1e6).toFixed(1) + "W")
        return parts.join(" · ")
    }

    // breeze names: battery-000 … battery-100, optional -charging
    readonly property string iconName: "battery-"
        + String(Math.round(percent / 10) * 10).padStart(3, "0")
        + (charging ? "-charging" : "")

    toolTipMainText: "Batteries"
    toolTipSubText: readout + "\nClick: readout · Middle-click: details\nRight-click: power settings · Double right-click: widget menu"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            const out = (data["stdout"] || "").replace(/\s+$/, "")
            if (source === root.cmdRaw) {
                root.batteries = out.split("\n").filter(l => l).map(l => {
                    const f = l.split(" ")
                    return {
                        name: f[0],
                        status: f[1].replace(/_/g, " "),
                        capacity: parseInt(f[2]) || 0,
                        energy: parseInt(f[3]) || 0,
                        full: parseInt(f[4]) || 0,
                        power: parseInt(f[5]) || 0
                    }
                })
            } else if (source === root.cmdFull) {
                root.fullText = out
            }
            disconnectSource(source)
        }
    }

    function refresh() {
        exec.connectSource(cmdRaw)
        if (showDetails)
            exec.connectSource(cmdFull)
    }

    onShowDetailsChanged: if (showDetails) exec.connectSource(cmdFull)

    Timer {
        interval: root.cfg.refreshInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // a single right-click waits out the double-click interval before opening
    // the stock popup; a second right-click inside it gets the widget menu
    Timer {
        id: rightClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval
        onTriggered: exec.connectSource(root.cmdStock)
    }

    compactRepresentation: MouseArea {
        // the tray doesn't size compact items for us; without these the
        // icon and click area collapse to 0×0
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onPressed: mouse => {
            // second right-click: let the press through so plasma shows the widget menu
            if (mouse.button === Qt.RightButton && rightClickTimer.running) {
                rightClickTimer.stop()
                mouse.accepted = false
            }
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                rightClickTimer.start()
            else if (mouse.button === Qt.MiddleButton)
                root.showDetails = !root.showDetails
            else
                root.cfg.showReadout = !root.cfg.showReadout
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: root.iconName
        }
    }

    // required: without a fullRepresentation plasma treats the root item as the
    // full view and never creates the compact icon. shown only if something sets
    // expanded (the tray's own activation); our clicks use the dialog below.
    fullRepresentation: PlasmaComponents3.Label {
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        text: root.fullText || root.readout
        textFormat: Text.PlainText
        font.family: "monospace"
        padding: Kirigami.Units.largeSpacing
    }

    // popup above the icon; ignores focus loss so it stays up until toggled
    // off by clicking the icon again. details (middle-click) take precedence.
    PlasmaCore.Dialog {
        visualParent: root.compactRepresentationItem
        location: Plasmoid.location
        hideOnWindowDeactivate: false
        flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
        visible: (root.cfg.showReadout || root.showDetails) && root.compactRepresentationItem !== null
            && root.batteries.length > 0

        mainItem: Item {
            width: label.implicitWidth
            height: label.implicitHeight

            PlasmaComponents3.Label {
                id: label
                text: root.showDetails ? (root.fullText || "…") : root.readout
                textFormat: Text.PlainText
                font.family: root.showDetails ? "monospace" : Kirigami.Theme.defaultFont.family
                padding: Kirigami.Units.smallSpacing
            }
        }
    }
}
