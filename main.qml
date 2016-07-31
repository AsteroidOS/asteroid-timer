/*
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtFeedback 5.0
import org.asteroid.controls 1.0
import org.nemomobile.dbus 1.0

Application {
    id: app

    property var startDate: 0
    property int selectedTime: 0
    property int seconds: 5*60

    function zeroPad(n) {
        return (n < 10 ? "0" : "") + n
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#a64d8b" }
            GradientStop { position: 1.0; color: "#664d95" }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height*0.5
        ListView {
            id: minuteLV
            currentIndex: 5
            enabled: !timer.running
            height: parent.height
            width: parent.width/2-1
            clip: true
            spacing: 15
            model: 60
            delegate: Item {
                width: minuteLV.width
                height: 30
                Text {
                    text: index
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - 15
            preferredHighlightEnd: height / 2 + 15
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveVelocity: 800
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex
        }

        ListView {
            id: secondLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: parent.width/2-1
            clip: true
            spacing: 15
            model: 60
            delegate: Item {
                width: secondLV.width
                height: 30
                Text {
                    text: zeroPad(index)
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - 15
            preferredHighlightEnd: height / 2 + 15
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveVelocity: 800
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex
        }
    }

    Text {
        text: ":"
        color: "white"
        anchors.centerIn: parent
        font.pixelSize: parent.height/8
    }

    IconButton {
        id: iconButton
        iconName: timer.running ? "pause" : "timer-outline"
        iconColor: "white"
        pressedIconColor: "lightgrey"
        visible: seconds !== 0

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Units.dp(10)
        }

        onClicked: {
            if(timer.running)
                timer.stop()
            else
            {
                startDate = new Date
                selectedTime = seconds
                timer.start()
            }
        }
    }

    ThemeEffect {
         id: haptics
         effect: "PressStrong"
     }

    property DBusInterface _dbus: DBusInterface {
        id: dbus

        destination: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"

        busType: DBusInterface.SystemBus
    }

    Timer {
        id: timer
        running: false
        repeat: true
        interval: 500
        triggeredOnStart: true
        onTriggered: {
            if(seconds <= 0)
            {
                timer.stop()
                haptics.play()
                dbus.call("req_display_state_on", undefined)
                window.raise()
            }
            else
            {
                var currentDate = new Date
                seconds = selectedTime - (currentDate.getTime() - startDate.getTime())/1000
                secondLV.currentIndex = seconds%60
                minuteLV.currentIndex = seconds/60
            }
        }
    }
}
