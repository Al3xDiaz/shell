pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Sub-page with the hotspot's settings (network name and password). Reached
// from the "Hotspot settings" row on NetworkPage via nState.openSubPage.
PageBase {
    id: root

    property string errorMessage

    // The fields mirror the live values until the user types (typing breaks
    // the binding); this restores that, e.g. after cancelling or saving.
    function reset(): void {
        ssidField.text = Qt.binding(() => Hotspot.ssid);
        passwordField.text = Qt.binding(() => Hotspot.password);
        ssidField.isError = false;
        passwordField.isError = false;
        root.errorMessage = "";
        showToggle.checked = false;
    }

    function submit(): void {
        if (Hotspot.busy)
            return;

        root.errorMessage = "";
        const ssid = ssidField.text.trim();
        const password = passwordField.text;

        // SSID: 1-32 bytes (UTF-8).
        const ssidBytes = unescape(encodeURIComponent(ssid)).length;
        if (ssidBytes < 1 || ssidBytes > 32) {
            ssidField.isError = true;
            ssidField.forceActiveFocus();
            return;
        }

        // WPA2 passphrase: 8-63 printable ASCII characters.
        if (!/^[\x20-\x7e]{8,63}$/.test(password)) {
            passwordField.isError = true;
            passwordField.forceActiveFocus();
            return;
        }

        Hotspot.saveSettings(ssid, password);
    }

    title: qsTr("Hotspot settings")
    isSubPage: true

    Component.onCompleted: {
        Hotspot.refresh();
        root.reset();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        Connections {
            function onSettingsResult(ok: bool, error: string): void {
                if (ok) {
                    root.nState.closeSubPage();
                } else {
                    root.errorMessage = error;
                }
            }

            target: Hotspot
        }

        Connections {
            function onSubPageClosed(): void {
                root.reset();
            }

            target: root.nState
        }

        // Description of the section.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Share this PC's internet connection over Wi-Fi. Other devices can join using the network name and password below.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("While the hotspot is on, this PC's Wi-Fi adapter works as an access point, so it can't be connected to another Wi-Fi network at the same time. A wired connection keeps working.")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }

        StyledTextField {
            id: ssidField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            placeholderText: qsTr("Network name (SSID)")
            leadingIcon: "wifi"
            supportingText: qsTr("Up to 32 bytes")
            errorText: qsTr("Network name must be 1–32 bytes")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: passwordField.forceActiveFocus()
        }

        StyledTextField {
            id: passwordField

            Layout.fillWidth: true
            placeholderText: qsTr("Password")
            leadingIcon: "key"
            echoMode: showToggle.checked ? TextInput.Normal : TextInput.Password
            supportingText: qsTr("8–63 characters: letters, digits and symbols (no accents)")
            errorText: qsTr("Password must be 8–63 plain ASCII characters")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData

            onAccepted: root.submit()
        }

        ToggleRow {
            id: showToggle

            first: true
            last: true
            text: qsTr("Show password")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            visible: Hotspot.enabled
            text: qsTr("The hotspot is on: saving changes restarts it, and connected devices will need to reconnect.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: Tokens.spacing.extraSmall - parent.spacing
            spacing: Tokens.spacing.small

            TextButton {
                Layout.fillHeight: true
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                type: TextButton.Tonal
                text: qsTr("Cancel")
                onClicked: root.nState.closeSubPage() // resets via onSubPageClosed
            }

            TextButton {
                Layout.fillHeight: true
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                type: TextButton.Filled
                text: Hotspot.saving ? qsTr("Saving…") : qsTr("Save")
                stateLayer.disabled: Hotspot.busy
                onClicked: root.submit()
            }
        }
    }
}
