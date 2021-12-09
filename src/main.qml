/*
 * Copyright (C) 2021 Timo Könnecke <github.com/eLtMosen>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
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
import Nemo.Alarms 1.0

Application {
    id: app

    centerColor: "#E34FB1"
    outerColor: "#83155B"

    property var alarmObject: null
    property var startDate: 0
    property int selectedTime: 0
    property int seconds: 5*60

    function zeroPad(n) {
        return (n < 10 ? "0" : "") + n
    }

    AlarmsModel {
        id: alarmModel
        onlyCountdown: true
        onPopulatedChanged: {
            for (var i=0; rowCount() > i; i++) {
                // Get Alarm object using AlarmObjectRole(=0x0100)
                var alarm = alarmModel.data(alarmModel.index(i, 0), 0x0100)
                if (!alarm.enabled) {
                    alarm.deleteAlarm()
                } else {
                    alarmObject = alarm
                    startDate = new Date
                    seconds = alarm.triggerTime - (startDate.getTime()/1000)
                    selectedTime = seconds
                    timer.start()
                }
            }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.002
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.159

        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.016

        height: Dims.h(70)

        Spinner {
            id: hourLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: parent.width * 0.165
            model: 24
            delegate: SpinnerDelegate { text: zeroPad(index) }
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex + 3600*hourLV.currentIndex
        }

        Label {
            text: ":"
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -parent.height * 0.013
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.165
            font.pixelSize: Dims.l(9)
        }

        Spinner {
            id: minuteLV
            currentIndex: 5
            enabled: !timer.running
            height: parent.height
            width: parent.width * 0.165
            model: 60
            highlightMoveDuration: currentIndex != 0 ? 400 : 0
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex + 3600*hourLV.currentIndex
        }

        Label {
            text: ":"
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -parent.height * 0.013
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.165
            font.pixelSize: Dims.l(9)
        }

        Spinner {
            id: secondLV
            currentIndex: 0
            enabled: !timer.running
            height: parent.height
            width: parent.width * 0.165
            model: 60
            highlightMoveDuration: currentIndex != 0 ? 400 : 0
            onCurrentIndexChanged: if(enabled) seconds = secondLV.currentIndex + 60*minuteLV.currentIndex + 3600*hourLV.currentIndex
        }
    }

    IconButton {
        id: iconButton
        iconName: timer.running ? "ios-pause" : "ios-timer-outline"
        visible: seconds !== 0

        onClicked: {
            if (alarmObject !== null) {
                alarmObject.deleteAlarm()
                timer.stop()
            } else {
                alarmObject = alarmModel.createAlarm()
                alarmObject.countdown = true
                alarmObject.second = seconds-1
                alarmObject.title = "";
                alarmObject.enabled = true
                alarmObject.save()

                startDate = new Date
                selectedTime = seconds
                timer.start()
            }
        }
    }

    Timer {
        id: timer
        running: false
        repeat: true
        interval: 500
        triggeredOnStart: true
        onTriggered: {
            if(seconds <= 0) {
                timer.stop()
            } else {
                var currentDate = new Date
                seconds = selectedTime - (currentDate.getTime() - startDate.getTime())/1000
                secondLV.currentIndex = seconds%60
                minuteLV.currentIndex = (seconds%3600)/60
                hourLV.currentIndex = seconds/3600
            }
        }
    }
}
