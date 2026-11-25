/*
    Windows-Style Touchpad Gestures - a KWin script for KDE Plasma 6

    This script is the settings layer for the InputActions configuration in
    extras/inputactions-task-switcher.yaml:

    3 fingers up         -> open and hold the task switcher
    3 fingers left/right -> cycle apps; open recents when closed
    3 fingers down       -> cancel recents, or show the desktop
    4 fingers drag       -> sticky left-button drag; continue with one finger,
                            then tap once to drop

    InputActions does the gesture work. This script turns InputActions on or off
    so the task switcher setting works without editing the InputActions config,
    and applies changes without logging out.

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import org.kde.kwin

Item {
    id: root

    // Current setting (see contents/config/main.xml).
    property bool taskSwitcherEnabled: true

    // Whether InputActions is running inside KWin (null = not checked yet).
    property var inputActionsAvailable: null
    property var appliedInputActionsState: null

    function readBool(key, fallback) {
        const value = KWin.readConfig(key, fallback);
        return value === true || value === "true";
    }

    function loadConfig() {
        taskSwitcherEnabled = readBool("TaskSwitcherEnabled", true);

        const summary = `taskSwitcher=${taskSwitcherEnabled}`;
        if (summary !== lastSummary) {
            lastSummary = summary;
            console.info("Windows-Style Gestures settings:", summary);
        }
        applyInputActionsState();
    }
    property string lastSummary: ""

    // KWin only re-reads script settings when scripts are (re)started, which
    // the settings dialog doesn't do. Ask KWin to do it, then pick up the new
    // values. Throttled, and triggered by window focus changes (e.g. closing the
    // settings dialog), so changes apply without logging out.
    function refreshConfig() {
        const now = Date.now();
        if (now - refresh.lastRun < 1000) {
            return;
        }
        refresh.lastRun = now;
        refresh.call();
    }

    // Suspend/resume InputActions so the task switcher setting controls the
    // bundled recents and 4-finger drag gestures as a group.
    function applyInputActionsState() {
        if (inputActionsAvailable !== true || appliedInputActionsState === taskSwitcherEnabled) {
            return;
        }
        appliedInputActionsState = taskSwitcherEnabled;
        console.info("Windows-Style Gestures:", taskSwitcherEnabled ? "resuming" : "suspending", "InputActions gestures");
        if (taskSwitcherEnabled) {
            inputActionsResume.call();
        } else {
            inputActionsSuspend.call();
        }
    }

    Component.onCompleted: {
        loadConfig();
        inputActionsProbe.call();
    }

    // If the script is turned off, stop InputActions' gestures too.
    Component.onDestruction: {
        if (inputActionsAvailable === true) {
            inputActionsSuspend.call();
        }
    }

    Connections {
        target: Workspace
        function onWindowActivated() {
            root.refreshConfig();
        }
    }

    Connections {
        target: Options
        function onConfigChanged() {
            root.loadConfig();
        }
    }

    DBusCall {
        id: refresh
        property double lastRun: 0
        service: "org.kde.KWin"
        path: "/Scripting"
        dbusInterface: "org.kde.kwin.Scripting"
        method: "start"
        onFinished: {
            root.loadConfig();
            inputActionsProbe.call(); // InputActions may have been installed/enabled since
        }
    }

    // Ask KWin whether the InputActions plugin (effect "kwin_gestures") is loaded.
    DBusCall {
        id: inputActionsProbe
        service: "org.kde.KWin"
        path: "/Effects"
        dbusInterface: "org.kde.kwin.Effects"
        method: "isEffectLoaded"
        arguments: ["kwin_gestures"]
        onFinished: returnValue => {
            const available = returnValue[0] === true;
            if (root.inputActionsAvailable !== available) {
                root.inputActionsAvailable = available;
                root.appliedInputActionsState = null;
            }
            root.applyInputActionsState();
        }
        onFailed: {
            root.inputActionsAvailable = false;
            root.appliedInputActionsState = null;
        }
    }

    DBusCall {
        id: inputActionsSuspend
        service: "org.inputactions"
        path: "/"
        dbusInterface: "org.inputactions"
        method: "suspend"
    }

    DBusCall {
        id: inputActionsResume // reloading the config also resumes InputActions
        service: "org.inputactions"
        path: "/"
        dbusInterface: "org.inputactions"
        method: "reloadConfig"
    }
}
