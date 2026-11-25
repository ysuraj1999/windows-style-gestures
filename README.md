# Windows-Style Touchpad Gestures for KDE Plasma

Windows 11/Android-style 3-finger touchpad gestures for KDE Plasma 6. InputActions
drives the gestures; a small KWin script supplies the settings toggle that
suspends or resumes them. Swipe up to browse open windows and let go to switch,
or start a drag with four fingers. The task switcher toggle controls the recents
and 4-finger drag gestures as a group.

| Gesture | What it does |
|---|---|
| 3 fingers up | Opens the task switcher and holds it open. Keep your fingers on the pad to browse; lift to switch to the highlighted app after 300 ms |
| 3 fingers left/right while recents is open | Cycles through windows. Every swipe resets the 300 ms timer |
| 3 fingers left/right while recents is closed | Opens recents and cycles the same way as up |
| 3 fingers down while recents is open | Cancels recents without switching |
| 3 fingers down | Shows the desktop (hides all windows) |
| 4 fingers drag | Starts a left-button drag. Lift the four fingers and the drag stays held |
| 1 finger drag while holding | Continues the drag normally. The drag stays held |
| 1 finger tap while dragging | Releases/drops the drag |

The 4-finger drag replaces KDE's built-in 4-finger left/right virtual-desktop
swipe while InputActions is active. Start with four fingers and lift them; the
drag stays held. Put one finger down to continue; the drag stays locked until
you tap once with one finger to drop.

Recents opens mid-swipe, as soon as your fingers have travelled a short distance.
The commit waits until you lift and stop touching the trackpad.

## Requirements

- KDE Plasma 6 on **Wayland** (tested on Plasma 6.7.5, Fedora 44; Debian 13 with Plasma 6.3 works)
- A touchpad
- [InputActions](https://github.com/InputActions) with its KWin plugin (required, see below)

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

It installs the KWin script, turns it on, and sets InputActions up for the
gestures. Your existing InputActions config is backed up first; the installer
asks before replacing it (`./install.sh --yes` skips the question).

**Without the installer:** open **System Settings → Window Management → KWin Scripts**,
click **Install from File…**, pick `windows-style-gestures.kwinscript`, tick
**Windows-Style Touchpad Gestures** and click **Apply**. Then copy
`extras/inputactions-task-switcher.yaml` over `~/.config/inputactions/config.yaml`
or follow the InputActions steps below.

### InputActions (required)

KDE itself uses 3-finger left/right to switch virtual desktops, and a KWin script
cannot turn that off. InputActions can, and it can keep KDE's task switcher open
while you browse. Install it, then run `./install.sh` again:

- **Fedora:** `sudo dnf copr enable silvigarabis/inputactions` then
  `sudo dnf install inputactions inputactions-kwin`
- **Arch:** `yay -S inputactions-kwin` (AUR)
- **Others:** see the [InputActions KWin guide](https://wiki.inputactions.org/main/getting-started/kwin.html)

Use a current InputActions build: the bundled config uses its scripting support to
track the recents state.

With InputActions, 3-finger up opens the Alt+Tab task switcher and holds it.
Left/right opens recents too when it is closed, and cycles through windows while
it is open. After 300 ms without touching the trackpad, the highlighted window is
activated. For a more Android-like look,
set **System Settings → Window Management → Task Switcher → Layout** to
**Thumbnail Grid** (the installer leaves your layout unchanged).

A 4-finger swipe presses and holds the left mouse button. The drag is sticky:
lift all four fingers and it stays held, then continue with one finger. The
one-finger movement is ordinary pointer motion, so it cannot release the drag.
Tap once with one finger to drop. This takes over KDE's 4-finger left/right
virtual-desktop swipe.

## Turn gestures on or off

Open **System Settings → Window Management → KWin Scripts** and click the settings
button next to **Windows-Style Touchpad Gestures**:

- **3-finger recents and 4-finger drag:** this toggle controls the
  up/left/right/down recents gestures and the 4-finger drag together. Turning it
  off suspends InputActions, restoring KDE's normal 3-finger desktop swipe and
  4-finger virtual-desktop swipe.

The 300 ms recents commit delay matches libinput's tap-and-drag lock timeout. It
lives in `~/.config/inputactions/config.yaml` as the `resume_timeout` values. Edit
all three, save, and the config reloads automatically. The left/right step distance
is the `interval: 60` values in the same file; lower is more sensitive.

The 4-finger drag deliberately has no `resume_timeout` and no one-finger
movement trigger: the one-finger phase is native pointer movement, so it cannot
release the drag. Tap once with one finger to drop. If the four-finger drag feels
slower than normal pointer movement, change `mouse: [ move_by_delta ]` to e.g.
`mouse: [ move_by_delta 1.5 ]` in the same file.

Changes apply as soon as you switch to another window; no need to log out.
To turn everything off, untick the script in KWin Scripts.

## Known limitations

- After **updating** the script, log out and back in: KWin keeps running the old
  version until then.
- The task switcher toggle pauses and resumes InputActions as a whole. If you use
  InputActions for other gestures too, turning the task switcher off pauses those as well.
- The drag is sticky: after the handoff to one finger, it stays held until you tap
  once with one finger or click physically. Lifting the one finger does not drop it.
- The drop tap needs tap-to-click enabled. Without it, use a physical click or the
  emergency key combination.
- Lift your fingers before swiping sideways in recents. Changing direction without
  lifting cancels the up trigger; the next left/right swipe is what starts cycling.
  Swiping down cancels recents and releases Alt. If Alt ever gets stuck, a 3-finger
  down swipe releases it.
- If you replace the installed InputActions config with your own, the KWin script
  stops acting on the bundled gestures while InputActions is loaded. Turn off the
  task switcher toggle or run `./install.sh` again to restore the bundled config.
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
