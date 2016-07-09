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

    ProgressCircle {
        id: circle
        anchors.fill: parent
        _start_angle: -Math.PI*3/2
        _end_angle: Math.PI/2
        property int seconds: 120
        value: seconds/(30*60)

        MouseArea {
            id: mouseArea
            anchors.fill: parent

            onPositionChanged: if(mouseArea.pressed) circle.seconds = mouseArea.valueFromPoint(mouseArea.mouseX, mouseArea.mouseY)*30*60;
            onPressed:                               circle.seconds = mouseArea.valueFromPoint(mouseArea.mouseX, mouseArea.mouseY)*30*60;

            function valueFromPoint(x, y) {
                var yy = circle.height / 2 - y;
                var xx = x - circle.width / 2;

                var angle = (xx || yy) ? Math.atan2(yy, xx) : 0;

                if(angle < -Math.PI / 2)
                    angle += 2 * Math.PI;

                var v = (Math.PI * 4 / 3 - angle) / (Math.PI * 10 / 6);
                return Math.max(0, Math.min(1, v));
            }
        }

        Text {
            anchors.centerIn: parent
            font.pixelSize: 40
            text: zeroPad(Math.floor(circle.seconds/60)) + ":" + zeroPad(Math.floor((circle.seconds%60)))
            function zeroPad(n) {
                return (n < 10 ? "0" : "") + n
            }
        }

        IconButton {
            id: iconButton
            iconName: timer.running ? "pause" : "timer-outline"
            iconColor: "black"
            visible: circle.seconds !== 0

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Units.dp(13)
            }

            onClicked: {
                if(timer.running)
                    timer.stop()
                else
                {
                    startDate = new Date
                    selectedTime = circle.seconds
                    timer.start()
                }
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
        onTriggered: {
            if(circle.seconds <= 0)
            {
                timer.stop()
                haptics.play()
                dbus.call("req_display_state_on", undefined)
                window.raise()
            }
            else
            {
                var currentDate = new Date
                circle.seconds = selectedTime + (startDate.getTime() - currentDate.getTime())/1000
            }
        }
    }
}
