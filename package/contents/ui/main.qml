/*
    Windows-Style Touchpad Gestures - a KWin script for KDE Plasma 6

    3 fingers up         -> Overview (like Windows Task View); if the desktop is
                            being shown, brings the windows back instead
    3 fingers down       -> show the desktop; if Overview is open, closes it instead
    3 fingers left/right -> task switcher

    Each gesture can be switched on or off in the script's settings.

    The task switcher works best with InputActions installed: it shows the
    Alt+Tab switcher while you slide and blocks KDE's own 3-finger desktop
    swipe. This script turns InputActions on or off to match the setting.
    Without InputActions, a swipe switches one app at a time, and only when
    there is a single virtual desktop (otherwise KDE's desktop swipe wins).

    Actions fire mid-swipe, as soon as the fingers have travelled the configured
    distance, instead of waiting for the fingers to be lifted.

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import org.kde.kwin

Item {
    id: root

    // Current settings (see contents/config/main.xml).
    property bool swipeUpEnabled: true
    property bool swipeDownEnabled: true
    property bool taskSwitcherEnabled: true
    property real triggerPoint: 0.5

    // Whether InputActions is running inside KWin (null = not checked yet).
    property var inputActionsAvailable: null
    property var appliedInputActionsState: null

    function readBool(key, fallback) {
        const value = KWin.readConfig(key, fallback);
        return value === true || value === "true";
    }

    function loadConfig() {
        swipeUpEnabled = readBool("SwipeUpEnabled", true);
        swipeDownEnabled = readBool("SwipeDownEnabled", true);
        taskSwitcherEnabled = readBool("TaskSwitcherEnabled", true);
        const percent = Number(KWin.readConfig("TriggerDistance", 50));
        triggerPoint = Math.max(10, Math.min(100, percent)) / 100;

        const summary = `up=${swipeUpEnabled} down=${swipeDownEnabled} taskSwitcher=${taskSwitcherEnabled} distance=${Math.round(triggerPoint * 100)}%`;
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
    // settings dialog) and by swipes, so changes apply without logging out.
    function refreshConfig() {
        const now = Date.now();
        if (now - refresh.lastRun < 1000) {
            return;
        }
        refresh.lastRun = now;
        refresh.call();
    }

    // Turn InputActions on/off so it only takes over 3-finger left/right when
    // the task switcher is enabled.
    function applyInputActionsState() {
        if (inputActionsAvailable !== true || appliedInputActionsState === taskSwitcherEnabled) {
            return;
        }
        appliedInputActionsState = taskSwitcherEnabled;
        console.info("Windows-Style Gestures:", taskSwitcherEnabled ? "resuming" : "suspending", "InputActions task switcher");
        if (taskSwitcherEnabled) {
            inputActionsResume.call();
        } else {
            inputActionsSuspend.call();
        }
    }

    function overviewActive() {
        return Workspace.isEffectActive("overview");
    }

    function invokeKWinShortcut(name) {
        kwinShortcut.arguments = [name];
        kwinShortcut.call();
    }

    function setShowingDesktop(show) {
        showDesktopCall.arguments = [show];
        showDesktopCall.call();
    }

    function swipeUp() {
        if (overviewActive()) {
            return;
        }
        // Restore the windows if the desktop is shown, otherwise open Overview.
        showingDesktopQuery.call();
    }

    function swipeDown() {
        if (overviewActive()) {
            invokeKWinShortcut("Overview"); // toggles Overview closed
            return;
        }
        setShowingDesktop(true);
    }

    // Fallback task switcher, used only without InputActions and with a single
    // virtual desktop, so it never fights KDE's 3-finger desktop swipe.
    function switchApp(reverse) {
        if (!taskSwitcherEnabled || inputActionsAvailable === true || Workspace.desktops.length > 1) {
            return;
        }
        invokeKWinShortcut(reverse ? "Walk Through Windows (Reverse)" : "Walk Through Windows");
    }

    Component.onCompleted: {
        loadConfig();
        inputActionsProbe.call();
    }

    // If the script is turned off, stop InputActions' task switcher too.
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

    DBusCall {
        id: kwinShortcut
        service: "org.kde.kglobalaccel"
        path: "/component/kwin"
        dbusInterface: "org.kde.kglobalaccel.Component"
        method: "invokeShortcut"
    }

    DBusCall {
        id: showDesktopCall
        service: "org.kde.KWin"
        path: "/KWin"
        dbusInterface: "org.kde.KWin"
        method: "showDesktop"
    }

    DBusCall {
        id: showingDesktopQuery
        service: "org.kde.KWin"
        path: "/KWin"
        dbusInterface: "org.freedesktop.DBus.Properties"
        method: "Get"
        arguments: ["org.kde.KWin", "showingDesktop"]
        onFinished: returnValue => {
            if (returnValue[0] === true) {
                root.setShowingDesktop(false);
            } else {
                root.invokeKWinShortcut("Overview");
            }
        }
    }

    // A 3-finger touchpad swipe that fires once, mid-swipe, at the trigger point.
    component Swipe: SwipeGestureHandler {
        property bool fired: false
        signal triggered()

        deviceType: SwipeGestureHandler.Device.Touchpad
        fingerCount: 3

        onProgressChanged: {
            if (!fired && progress < 0.1) {
                root.refreshConfig(); // swipe just started
            }
            const point = root.triggerPoint;
            if (!fired && progress >= point) {
                fired = true;
                triggered();
            } else if (fired && progress < point / 2) {
                // New swipe, or the fingers went most of the way back: re-arm.
                fired = false;
            }
        }
        onActivated: fired = false
        onCancelled: fired = false
    }

    Swipe {
        direction: SwipeGestureHandler.Direction.Up
        onTriggered: {
            if (root.swipeUpEnabled) {
                root.swipeUp();
            }
        }
    }

    Swipe {
        direction: SwipeGestureHandler.Direction.Down
        onTriggered: {
            if (root.swipeDownEnabled) {
                root.swipeDown();
            }
        }
    }

    Swipe {
        direction: SwipeGestureHandler.Direction.Right
        onTriggered: root.switchApp(false)
    }

    Swipe {
        direction: SwipeGestureHandler.Direction.Left
        onTriggered: root.switchApp(true)
    }

    // Same actions as keyboard shortcuts (unassigned by default; set them in
    // System Settings > Keyboard > Shortcuts > KWin if you want them).
    ShortcutHandler {
        name: "Windows-Style Gestures: Swipe Up"
        text: "Windows-Style Gestures: Overview / restore windows"
        sequence: ""
        onActivated: root.swipeUp()
    }

    ShortcutHandler {
        name: "Windows-Style Gestures: Swipe Down"
        text: "Windows-Style Gestures: Show desktop / close Overview"
        sequence: ""
        onActivated: root.swipeDown()
    }
}
