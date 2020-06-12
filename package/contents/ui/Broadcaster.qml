/*
*  Copyright 2019 Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of applet-window-title
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.7

Item{
    id: broadcaster

    property bool hiddenFromBroadcast: false

    readonly property bool showWindowTitleEnabled: plasmoid.configuration.showWindowTitleOnMouseExit && !inEditMode
    readonly property bool menuIsPresent: appMenuModel.visible && appMenuModel.menuAvailable
    readonly property bool isActive: plasmoid.configuration.windowTitleIsPresent && showWindowTitleEnabled
    property bool windowTitleRequestsCooperation: false

    readonly property bool cooperationEstablished: windowTitleRequestsCooperation && isActive

    function sendMessage() {
        if (cooperationEstablished) {
            broadcasterDelayer.start();
        }
    }

    function cancelMessage() {
        if (cooperationEstablished) {
            broadcasterDelayer.stop();
        }
    }

    Component.onDestruction: {
        if (latteBridge) {
            latteBridge.actions.broadcastToApplet("org.kde.windowtitle", "setCooperation", false);
        }
    }

    onIsActiveChanged: {
        if (latteBridge) {
            latteBridge.actions.broadcastToApplet("org.kde.windowtitle", "setCooperation", isActive);
        }
    }

    onMenuIsPresentChanged: {
        if (latteBridge) {
            latteBridge.actions.broadcastToApplet("org.kde.windowtitle", "menuIsPresent", menuIsPresent);
        }
    }

    onCooperationEstablishedChanged: {
        broadcaster.hiddenFromBroadcast = cooperationEstablished;
    }

    Connections {
        target: latteBridge
        onBroadcasted: {
            if (cooperationEstablished && action === "setVisible") {
                broadcaster.hiddenFromBroadcast = !value;
            } else if (action === "isPresent") {
                plasmoid.configuration.windowTitleIsPresent = true;
                latteBridge.actions.broadcastToApplet("org.kde.windowtitle", "isPresent", true);
            } else if (action === "setCooperation") {
                broadcaster.windowTitleRequestsCooperation = value;
            }
        }
    }

    Connections {
        target: buttonGrid
        onContainsMouseChanged: {
            if (broadcaster.cooperationEstablished) {
                if (buttonGrid.containsMouse) {
                    broadcaster.cancelMessage();
                } else {
                    broadcaster.sendMessage();
                }
            }
        }
    }

    Timer{
        id: broadcasterDelayer
        interval: 5
        onTriggered: {
            if (cooperationEstablished) {
                if (!buttonGrid.containsMouse) {
                    broadcaster.hiddenFromBroadcast = true;
                    latteBridge.actions.broadcastToApplet("org.kde.windowtitle", "setVisible", true);
                } else {
                    broadcaster.hiddenFromBroadcast = false;
                    latteBridge.actions.broadcastToApplet("org.kde.windowtitle", "setVisible", false);
                }
            }
        }
    }
}
