#!/bin/sh
# Removes Windows-Style Touchpad Gestures for the current user and restores
# the InputActions config that install.sh backed up (if any).
set -e

cd "$(dirname "$0")"
ID=windowsstylegestures
IA_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/inputactions/config.yaml"
IA_BACKUP="$IA_CONFIG.before-windows-style-gestures"

say() { printf '%s\n' "$*"; }

# dbus SERVICE PATH INTERFACE METHOD
dbus() {
    if command -v busctl >/dev/null 2>&1; then
        busctl --user call "$1" "$2" "$3" "$4" >/dev/null
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest "$1" --object-path "$2" --method "$3.$4" >/dev/null
    else
        return 1
    fi
}

# Turn the script off first so KWin unloads it.
kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" false
dbus org.kde.KWin /Scripting org.kde.kwin.Scripting start || true

if kpackagetool6 --type=KWin/Script --list 2>/dev/null | grep -qx "$ID"; then
    kpackagetool6 --type=KWin/Script --remove "$ID" >/dev/null
    say "Removed the KWin script."
fi

if [ -f "$IA_BACKUP" ]; then
    mv "$IA_BACKUP" "$IA_CONFIG"
    say "Restored your previous InputActions config."
elif [ -f "$IA_CONFIG" ] && cmp -s "$IA_CONFIG" extras/inputactions-task-switcher.yaml; then
    rm "$IA_CONFIG"
    say "Removed the task switcher InputActions config."
fi
# Reloading the config also resumes InputActions if the script had paused it.
dbus org.inputactions / org.inputactions reloadConfig 2>/dev/null || true

say "Done."
