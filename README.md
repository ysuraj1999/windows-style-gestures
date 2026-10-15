# Windows-Style Touchpad Gestures for KDE Plasma

Windows 11-style 3-finger touchpad gestures for KDE Plasma 6, as a KWin script.
Every gesture can be turned on or off.

| Gesture | What it does |
|---|---|
| 3 fingers up | Opens Overview (KDE's version of Windows Task View) |
| 3 fingers up after showing the desktop | Brings all windows back, exactly as they were |
| 3 fingers down | Shows the desktop (hides all windows) |
| 3 fingers down while Overview is open | Closes Overview |
| 3 fingers left/right | Task switcher: the Alt+Tab view opens, keep sliding to pick an app, lift to switch |
| 4 fingers left/right | Switches virtual desktops (KDE built-in, unchanged) |

Actions fire mid-swipe, as soon as your fingers have travelled a short distance.
You don't have to lift your fingers first.

## Requirements

- KDE Plasma 6 on **Wayland** (tested on Plasma 6.7.5, Fedora 44)
- A touchpad
- For the full task switcher: [InputActions](https://github.com/InputActions) (optional, see below)

## Install

Download this repository (green **Code** button → **Download ZIP**, then extract it),
or clone it:

```bash
git clone https://github.com/vivek1234-byte/windows-style-gestures.git
cd windows-style-gestures
```

Then run as your normal user (no `sudo`):

```bash
./install.sh
```

It installs the KWin script, turns it on, and, if InputActions is installed,
sets it up for the task switcher. Your existing InputActions config is backed up
first; the installer asks before replacing it (`./install.sh --yes` skips the question).

**Without the installer:** open **System Settings → Window Management → KWin Scripts**,
click **Install from File…**, pick `windows-style-gestures.kwinscript`, tick
**Windows-Style Touchpad Gestures** and click **Apply**. You get swipe up/down; for the
full task switcher, also follow the InputActions steps below.

### Optional: InputActions for the task switcher

KDE itself uses 3-finger left/right to switch virtual desktops, and a KWin script
cannot turn that off. InputActions can, and it also lets the Alt+Tab switcher follow
your fingers. Install it, then run `./install.sh` again:

- **Fedora:** `sudo dnf copr enable silvigarabis/inputactions` then
  `sudo dnf install inputactions inputactions-kwin`
- **Arch:** `yay -S inputactions-kwin` (AUR)
- **Others:** see the [InputActions KWin guide](https://wiki.inputactions.org/main/getting-started/kwin.html)

Without InputActions, left/right switches one app per swipe, and only if you use a
single virtual desktop (otherwise KDE's desktop swipe keeps working as normal).

## Turn gestures on or off

Open **System Settings → Window Management → KWin Scripts** and click the settings
button next to **Windows-Style Touchpad Gestures**:

- **3 fingers up:** Overview / bring windows back
- **3 fingers down:** Show desktop / close Overview
- **3 fingers left/right:** Task switcher. When this is off, the script also pauses
  InputActions, so 3-finger left/right goes back to switching virtual desktops.
- **Swipe distance:** how far you swipe before an action fires (default 50%).
  Lower is faster; higher makes accidental triggers less likely.

Changes apply as soon as you switch to another window or swipe again; no need to log out.
To turn everything off, untick the script in KWin Scripts.

## Keyboard shortcuts

The up/down actions are also available as keyboard shortcuts (unassigned by default)
in **System Settings → Keyboard → Shortcuts → KWin**:

- *Windows-Style Gestures: Overview / restore windows*
- *Windows-Style Gestures: Show desktop / close Overview*

## Known limitations

- After **updating** the script, log out and back in: KWin keeps running the old
  version until then.
- If your virtual desktops are arranged in **more than one row**, KDE also uses
  3-finger up/down to move between rows, and both actions will happen.
- The task switcher toggle pauses and resumes InputActions as a whole. If you use
  InputActions for other gestures too, turning the task switcher off pauses those as well.
- Other gesture tools (Touchégg, Fusuma) can take over the same swipes.

## Uninstall

```bash
./uninstall.sh
```

This removes the script and restores the InputActions config you had before
installing. Or untick and remove the script in KWin Scripts.

## Build the .kwinscript file

```bash
./build.sh
```

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
