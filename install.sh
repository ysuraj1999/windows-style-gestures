#!/bin/sh
# Installs Windows-Style Touchpad Gestures for the current user.
#
#   ./install.sh        install or update, asking before replacing an InputActions config
#   ./install.sh --yes  same, without asking
#
# Installs the KWin script and turns it on. InputActions is required for the
# gestures: its config is installed here (your old config is backed up first).
# No root needed.
set -e

cd "$(dirname "$0")"
ID=windowsstylegestures
IA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/inputactions"
IA_CONFIG="$IA_DIR/config.yaml"
IA_BACKUP="$IA_CONFIG.before-windows-style-gestures"
ASSUME_YES=no
[ "$1" = "--yes" ] && ASSUME_YES=yes

say() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

# dbus SERVICE PATH INTERFACE METHOD [STRING_ARG]
dbus() {
    if command -v busctl >/dev/null 2>&1; then
        busctl --user call "$1" "$2" "$3" "$4" ${5:+s "$5"} >/dev/null
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest "$1" --object-path "$2" --method "$3.$4" ${5:+"$5"} >/dev/null
    else
        return 1
    fi
}

[ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root."
command -v kpackagetool6 >/dev/null 2>&1 || die "kpackagetool6 not found. This needs KDE Plasma 6."
command -v kwriteconfig6 >/dev/null 2>&1 || die "kwriteconfig6 not found. This needs KDE Plasma 6."
[ -f package/metadata.json ] || die "run this from the windows-style-gestures folder."

# 1. KWin script
UPDATED=no
if kpackagetool6 --type=KWin/Script --list 2>/dev/null | grep -qx "$ID"; then
    say "Updating the KWin script..."
    kpackagetool6 --type=KWin/Script --upgrade package >/dev/null
    UPDATED=yes
else
    say "Installing the KWin script..."
    kpackagetool6 --type=KWin/Script --install package >/dev/null
fi
kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" true

# 2. InputActions (required for the gestures)
has_inputactions() {
    dbus org.inputactions / org.inputactions issues 2>/dev/null \
        || command -v inputactions >/dev/null 2>&1
}

if has_inputactions; then
    install_ia_config=yes
    if [ -f "$IA_CONFIG" ] && ! cmp -s "$IA_CONFIG" extras/inputactions-task-switcher.yaml; then
        if [ "$ASSUME_YES" = no ]; then
            printf 'Replace your InputActions config with the task switcher config? A backup is kept. [Y/n] '
            read -r answer || answer=n
            case "$answer" in [Nn]*) install_ia_config=no ;; esac
        fi
        if [ "$install_ia_config" = yes ] && [ ! -f "$IA_BACKUP" ]; then
            cp "$IA_CONFIG" "$IA_BACKUP"
            say "Backed up your InputActions config to $IA_BACKUP"
        fi
    fi
    if [ "$install_ia_config" = yes ]; then
        mkdir -p "$IA_DIR"
        cp extras/inputactions-task-switcher.yaml "$IA_CONFIG"
        kwriteconfig6 --file kwinrc --group Plugins --key kwin_gesturesEnabled true
        dbus org.kde.KWin /Effects org.kde.kwin.Effects loadEffect kwin_gestures 2>/dev/null || true
        dbus org.inputactions / org.inputactions reloadConfig 2>/dev/null || true
        say "InputActions set up for the recents and 4-finger drag gestures."
        say "3-finger up or left/right opens recents; lift to switch after 300 ms."
        say "4-finger drag stays held; continue with one finger, then tap once to drop."
        say "Tip: set Task Switcher > Layout to Thumbnail Grid for window previews."
    else
        say "Left your InputActions config unchanged."
    fi
else
    say ""
    say "InputActions is required for the gestures. Install it, then run ./install.sh again:"
    case "$(. /etc/os-release 2>/dev/null; echo "$ID $ID_LIKE")" in
        *fedora*) say "  sudo dnf copr enable silvigarabis/inputactions"
                  say "  sudo dnf install inputactions inputactions-kwin" ;;
        *arch*)   say "  yay -S inputactions-kwin   (from the AUR)" ;;
        *)        say "  See https://wiki.inputactions.org/main/getting-started/kwin.html" ;;
    esac
    say "Then log out and back in, and run ./install.sh again."
fi

# 3. Load the script now
dbus org.kde.KWin /Scripting org.kde.kwin.Scripting start || true

say ""
if [ "$UPDATED" = yes ]; then
    say "Done. Log out and back in so KWin loads the new version."
else
    say "Done. The gestures work now."
fi
say "Turn individual gestures on or off in:"
say "  System Settings > Window Management > KWin Scripts > Windows-Style Touchpad Gestures (settings button)"
