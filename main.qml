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

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.nemomobile.ngf 1.0
import org.nemomobile.dbus 1.0
import org.nemomobile.keepalive 1.1

Application {
    id: app

    centerColor: "#E34FB1"
    outerColor: "#83155B"

    property var startDate: 0
    property int selectedTime: 0
    property int seconds: 5*60

    function zeroPad(n) {
        return (n < 10 ? "0" : "") + n
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: Dims.h(50)
        ListView {
            id: hourLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: Dims.w(20)
            clip: true
            spacing: Dims.l(2)
            model: 10
            delegate: Item {
                width: hourLV.width
                height: Dims.h(10)
                Text {
                    text: index
                    anchors.centerIn: parent
                    color: parent.PathView.isCurrentItem ? "#FFFFFF" : "#88FFFFFF"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - Dims.h(5)
            preferredHighlightEnd: height / 2 + Dims.h(5)
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 400
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex + 3600*hourLV.currentIndex
        }

        Text {
            text: ":"
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            width: Dims.w(20)
            font.pixelSize: Dims.l(12)
        }

        ListView {
            id: minuteLV
            currentIndex: 5
            enabled: !timer.running
            height: parent.height
            width: Dims.w(20)
            clip: true
            spacing: Dims.l(2)
            model: 60
            delegate: Item {
                width: minuteLV.width
                height: Dims.h(10)
                Text {
                    text: zeroPad(index)
                    anchors.centerIn: parent
                    color: parent.PathView.isCurrentItem ? "#FFFFFF" : "#88FFFFFF"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - Dims.h(5)
            preferredHighlightEnd: height / 2 + Dims.h(5)
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: currentIndex != 0 ? 400 : 0
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex + 3600*hourLV.currentIndex
        }

        Text {
            text: ":"
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            width: Dims.w(20)
            font.pixelSize: Dims.l(12)
        }

        ListView {
            id: secondLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: Dims.w(20)
            clip: true
            spacing: Dims.l(2)
            model: 60
            delegate: Item {
                width: secondLV.width
                height: Dims.h(10)
                Text {
                    text: zeroPad(index)
                    anchors.centerIn: parent
                    color: parent.PathView.isCurrentItem ? "#FFFFFF" : "#88FFFFFF"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - Dims.h(5)
            preferredHighlightEnd: height / 2 + Dims.h(5)
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: currentIndex != 0 ? 400 : 0
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex + 3600*hourLV.currentIndex
        }
    }

    IconButton {
        id: iconButton
        iconName: timer.running ? "ios-pause" : "ios-timer-outline"
        visible: seconds !== 0

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Dims.iconButtonMargin
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
                feedback.play()
                dbus.call("req_display_state_on", undefined)
                window.raise()
            }
            else
            {
                var currentDate = new Date
                seconds = selectedTime - (currentDate.getTime() - startDate.getTime())/1000
                secondLV.currentIndex = seconds%60
                minuteLV.currentIndex = (seconds%3600)/60
                hourLV.currentIndex = seconds/3600
            }
        }
        onRunningChanged: DisplayBlanking.preventBlanking = running
    }
}
