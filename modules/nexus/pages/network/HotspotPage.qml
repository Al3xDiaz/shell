pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Sub-page for changing the hotspot password. Reached from the "Hotspot
// password" row on NetworkPage via nState.openSubPage.
PageBase {
    id: root

    property string errorMessage

    function submit(): void {
        if (Hotspot.busy)
            return;

        // WPA2 passphrase: 8-63 printable ASCII characters.
        if (!/^[\x20-\x7e]{8,63}$/.test(passwordField.text)) {
            root.errorMessage = "";
            passwordField.isError = true;
            passwordField.forceActiveFocus();
            return;
        }

        root.errorMessage = "";
        Hotspot.setPassword(passwordField.text);
    }

    title: qsTr("Hotspot password")
    isSubPage: true

    Component.onCompleted: Hotspot.refresh()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        Connections {
            function onPasswordResult(ok: bool, error: string): void {
                if (ok) {
                    root.nState.closeSubPage();
                } else {
                    root.errorMessage = error;
                    passwordField.isError = true;
                }
            }

            target: Hotspot
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            text: Hotspot.ssid.length > 0 ? qsTr("Choose a new password for the “%1” hotspot.").arg(Hotspot.ssid) : qsTr("Choose a new password for the hotspot.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        StyledTextField {
            id: passwordField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            placeholderText: qsTr("New password")
            leadingIcon: "key"
            echoMode: showToggle.checked ? TextInput.Normal : TextInput.Password
            supportingText: qsTr("8–63 characters, letters, digits and symbols (no accents)")
            errorText: root.errorMessage.length > 0 ? root.errorMessage : qsTr("Password must be 8–63 plain ASCII characters")
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
            visible: Hotspot.enabled
            text: qsTr("The hotspot is on: it will restart and connected devices will need to reconnect with the new password.")
            color: Colours.palette.m3outline
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
                onClicked: root.nState.closeSubPage()
            }

            TextButton {
                Layout.fillHeight: true
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                type: TextButton.Filled
                text: Hotspot.changingPassword ? qsTr("Saving…") : qsTr("Save")
                stateLayer.disabled: Hotspot.busy
                onClicked: root.submit()
            }
        }
    }
}
