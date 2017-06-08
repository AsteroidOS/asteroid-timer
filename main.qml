/*
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
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
import org.asteroid.controls 1.0
import org.nemomobile.ngf 1.0
import org.nemomobile.dbus 1.0

Application {
    id: app

    centerColor: "#E34FB1"
    outerColor: "#83155B"

    Connections {
        target:  timer
        onRemainingSecChanged: {
            var sec = timer.remainingSec;
            hourLV.currentIndex = (sec/(60*60))%10;
            minuteLV.currentIndex = (sec/60)%60;
            secondLV.currentIndex = sec%60;
        }
        onElapsed: {
            hourLV.currentIndex   = 0;
            minuteLV.currentIndex = 0;
            secondLV.currentIndex = 0;
            feedback.play()
            dbus.call("req_display_state_on", undefined)
            window.raise()
        }
    }

    function zeroPad(n) {
        return (n < 10 ? "0" : "") + n
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height*0.5
        ListView {
            id: hourLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: parent.width/5-1
            clip: true
            spacing: 15
            model: 10
            delegate: Item {
                width: hourLV.width
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
            highlightMoveDuration: 400
        }

        Text {
            text: ":"
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            width: parent.width/5-1
            font.pixelSize: parent.height/8
        }

        ListView {
            id: minuteLV
            currentIndex: 5
            enabled: !timer.running
            height: parent.height
            width: parent.width/5-1
            clip: true
            spacing: 15
            model: 60
            delegate: Item {
                width: minuteLV.width
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
            highlightMoveDuration: currentIndex != 0 ? 400 : 0
        }

        Text {
            text: ":"
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            width: parent.width/5-1
            font.pixelSize: parent.height/8
        }

        ListView {
            id: secondLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: parent.width/5-1
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
            highlightMoveDuration: currentIndex != 0 ? 400 : 0
        }
    }

    IconButton {
        id: iconButton
        iconName: timer.running ? "ios-pause" : "ios-timer-outline"
        iconColor: "white"
        pressedIconColor: "lightgrey"
        visible: secondLV.currentIndex !== 0 || minuteLV.currentIndex !== 0 || hourLV.currentIndex !== 0

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Units.dp(10)
        }

        onClicked: {
            if(timer.running)
                timer.stop()
            else
                timer.start(secondLV.currentIndex, minuteLV.currentIndex, hourLV.currentIndex)
        }
    }

    NonGraphicalFeedback {
        id: feedback
        event: "email"
    }

    property DBusInterface _dbus: DBusInterface {
        id: dbus

        destination: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"

        busType: DBusInterface.SystemBus
    }
}
