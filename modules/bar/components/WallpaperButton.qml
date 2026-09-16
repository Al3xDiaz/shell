import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                WallpaperCycle.enabled = !WallpaperCycle.enabled;
            else
                WallpaperCycle.cycle();
        }
        onWheel: event => {
            if (event.angleDelta.y > 0)
                WallpaperCycle.previous();
            else if (event.angleDelta.y < 0)
                WallpaperCycle.cycle();
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "wallpaper"
        color: WallpaperCycle.enabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
