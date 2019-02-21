/*!
 * This file is part of WatchFlower.
 * COPYRIGHT (C) 2019 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

import QtQuick 2.7
import QtQuick.Controls 2.0

import com.watchflower.theme 1.0

ApplicationWindow {
    id: applicationWindow
    color: Theme.colorMaterialLightGrey
    visible: true

    width: 480
    height: 720
    minimumWidth: 480
    minimumHeight: 720

    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint

    // Desktop stuff

    DesktopGeometrySaver {
        window: applicationWindow
        windowName: "applicationWindow"
    }

    // Events handling /////////////////////////////////////////////////////////

    Connections {
        target: header
        onBackButtonClicked: {
            if (content.state !== "DeviceList") {
                content.state = "DeviceList"
            }
        }
        onRefreshButtonClicked: {
            deviceManager.refreshDevices()
        }
        onRescanButtonClicked: {
            deviceManager.scanDevices()
        }
        onSettingsButtonClicked: content.state = "Settings"
        onAboutButtonClicked: content.state = "About"
        onExitButtonClicked: settingsManager.exit()
    }
    Connections {
        target: content
        onStateChanged: {
            if (content.state === "DeviceList") {
                header.leftIcon.source = "qrc:/assets/watchflower.svg"
            } else {
                header.leftIcon.source = "qrc:/assets/menu_back.svg"
            }
        }
    }
    Connections {
        target: systrayManager
        onSettingsClicked: {
            content.state = "Settings"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: {
            if (mouse.button === Qt.BackButton) {
                content.state = "DeviceList"
            } else if (mouse.button === Qt.ForwardButton) {
                if (curentlySelectedDevice)
                    content.state = "DeviceDetails"
            }
        }
    }
    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            content.state = "DeviceList"
        }
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: {
            if (curentlySelectedDevice)
                content.state = "DeviceDetails"
        }
    }
    Item {
        focus: true
        Keys.onBackPressed: {
            content.state = "DeviceList"
        }
    }
    onClosing: {
        if (Qt.platform.os === "android" || Qt.platform.os === "ios") {
            close.accepted = false;
        } else {
            close.accepted = false;
            applicationWindow.hide()
        }
    }

    // QML /////////////////////////////////////////////////////////////////////

    property var curentlySelectedDevice: null

    DesktopHeader {
        id: header
        width: parent.width
        anchors.top: parent.top
    }

    Item {
        id: content
        anchors.top: header.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        MobileDeviceList {
            anchors.fill: parent
            id: screenDeviceList
        }
        DeviceScreen {
            anchors.fill: parent
            id: screenDeviceDetails
        }
        MobileSettings {
            anchors.fill: parent
            id: screenSettings
        }
        MobileAbout {
            anchors.fill: parent
            id: screenAbout
        }

        state: "DeviceList"
        states: [
            State {
                name: "DeviceList"

                PropertyChanges {
                    target: screenDeviceList
                    enabled: true
                    visible: true
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    enabled: false
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    enabled: false
                    visible: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                    enabled: false
                }
            },
            State {
                name: "DeviceDetails"

                PropertyChanges {
                    target: screenDeviceList
                    enabled: false
                    visible: false
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    enabled: true
                    visible: true
                }
                PropertyChanges {
                    target: screenSettings
                    enabled: false
                    visible: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                    enabled: false
                }
                StateChangeScript {
                    name: "secondScript"
                    script: screenDeviceDetails.loadDevice()
                }
            },
            State {
                name: "Settings"

                PropertyChanges {
                    target: screenDeviceList
                    visible: false
                    enabled: false
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    visible: false
                    enabled: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: true
                    enabled: true
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                    enabled: false
                }
            },
            State {
                name: "About"

                PropertyChanges {
                    target: screenDeviceList
                    visible: false
                    enabled: false
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    visible: false
                    enabled: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                    enabled: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: true
                    enabled: true
                }
            }
        ]
    }
}
