// SDDM theme mirroring ~/.config/hypr/hyprlock.conf:
// blurred wallpaper, vertical HH/MM clock, date, round avatar, pill password field.
import QtQuick 2.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "black"

    property string userName: userModel.lastUser !== "" ? userModel.lastUser : config.defaultUser
    property int sessionIndex: sessionModel.lastIndex
    property string fontFamily: "JetBrainsMono Nerd Font"
    // hyprlock positions are in pixels on a 1080p screen; scale them to this screen
    property real s: height / 1080

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            hour.text = Qt.formatTime(now, "HH")
            minute.text = Qt.formatTime(now, "mm")
            date.text = Qt.formatDate(now, "dddd, dd MMM")
        }
    }

    // --- vertical clock + date (hyprlock: valign center, y offsets 230 / 115 / 35) ---
    Text {
        id: hour
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 230 * s - height / 2
        color: Qt.rgba(1, 1, 1, 0.9)
        font { family: root.fontFamily; pixelSize: 106 * s; weight: Font.ExtraBold }
    }
    Text {
        id: minute
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 115 * s - height / 2
        color: Qt.rgba(1, 1, 1, 0.9)
        font { family: root.fontFamily; pixelSize: 106 * s; weight: Font.ExtraBold }
    }
    Text {
        id: date
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 35 * s - height / 2
        color: Qt.rgba(1, 1, 1, 0.6)
        font { family: root.fontFamily; pixelSize: 17 * s }
    }

    // --- avatar (hyprlock: size 130, border 4 black, valign bottom, y 160) ---
    Rectangle {
        id: avatarBorder
        width: (130 + 8) * s; height: width; radius: width / 2
        color: "black"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (160 - 4) * s
        Image {
            anchors.centerIn: parent
            width: 130 * s; height: width
            source: "avatar.png"
            smooth: true
            mipmap: true
        }
    }

    // --- password field (hyprlock: 210x40, outline 2, valign bottom, y 100) ---
    Rectangle {
        id: field
        width: 210 * s; height: 40 * s; radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.3)
        border { width: 2; color: password.activeFocus ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.2) }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s

        TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 14 * s; anchors.rightMargin: 14 * s
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            color: "#c8c8c8" // hyprlock font_color rgb(200, 200, 200)
            selectionColor: Qt.rgba(1, 1, 1, 0.3)
            font { family: root.fontFamily; pixelSize: 14 * s; letterSpacing: 4 * s } // hyprlock dots_spacing
            focus: true
            clip: true
            onAccepted: {
                message.text = ""
                sddm.login(root.userName, text, root.sessionIndex)
            }
        }
        Text {
            anchors.centerIn: parent
            visible: password.text === ""
            text: "Password..."
            color: Qt.rgba(1, 1, 1, 0.6)
            font { family: root.fontFamily; pixelSize: 14 * s }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 10; duration: 50 }
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -6; duration: 50 }
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
        }
    }

    Text {
        id: message
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: field.bottom
        anchors.topMargin: 12 * s
        color: "#ff8080"
        font { family: root.fontFamily; pixelSize: 13 * s }
    }

    // --- small power buttons, bottom-right (not in hyprlock, but needed before login) ---
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 24 * s
        spacing: 22 * s
        Repeater {
            model: [
                { icon: "", tip: "reboot", ok: sddm.canReboot },
                { icon: "", tip: "poweroff", ok: sddm.canPowerOff }
            ]
            Text {
                visible: modelData.ok
                text: modelData.icon
                color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.5)
                font { family: root.fontFamily; pixelSize: 20 * s }
                MouseArea {
                    id: area
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: modelData.tip === "reboot" ? sddm.reboot() : sddm.powerOff()
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            message.text = "Wrong password"
            shake.start()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
