import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showReadout: showReadout.checked
    property alias cfg_refreshInterval: refreshInterval.value
    property alias cfg_internalLabel: internalLabel.text
    property alias cfg_externalLabel: externalLabel.text
    property alias cfg_showArrows: showArrows.checked
    property alias cfg_showPower: showPower.checked
    property alias cfg_stockBatteryWidgetId: stockBatteryWidgetId.value
    property alias cfg_battPath: battPath.text

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showReadout
            Kirigami.FormData.label: "Readout popup:"
            text: "Shown (left-click the icon to toggle)"
        }

        QQC2.SpinBox {
            id: refreshInterval
            Kirigami.FormData.label: "Refresh every:"
            from: 1
            to: 60
            textFromValue: (value) => value + " s"
            valueFromText: (text) => parseInt(text)
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextField {
            id: internalLabel
            Kirigami.FormData.label: "Internal battery label:"
        }

        QQC2.TextField {
            id: externalLabel
            Kirigami.FormData.label: "Rear battery label:"
        }

        QQC2.CheckBox {
            id: showArrows
            Kirigami.FormData.label: "Show:"
            text: "▲ / ▼ charging arrows"
        }

        QQC2.CheckBox {
            id: showPower
            text: "Total power (W)"
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: stockBatteryWidgetId
            Kirigami.FormData.label: "Stock battery widget ID:"
            from: 0
            to: 9999
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            text: "Right-click opens this tray widget through its \"activate widget N\" global shortcut. 0 means not set up: right-click then just offers Configure. setup.sh (run by install.sh) fills this in."
        }

        QQC2.TextField {
            id: battPath
            Kirigami.FormData.label: "batt script:"
        }
    }
}
