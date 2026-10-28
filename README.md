# Chalkfy

A menu bar app to point at things on a shared screen during a live call, on macOS 14+.

## Install

1. Run `brew install --cask lorransr/tap/chalkfy`, and `brew upgrade --cask chalkfy` to update. Or download `Chalkfy.zip` from [Releases](https://github.com/lorransr/chalkfy/releases), unzip it and move `Chalkfy.app` to Applications.
2. Open it. Chalkfy is not notarized, so macOS blocks it: click Done, then in System Settings > Privacy & Security click "Open Anyway" and confirm. An update may ask for this again.
3. From the menu bar icon, choose "Request Accessibility Permission" and turn Chalkfy on. The Laser needs it; the grant applies with no relaunch and survives updates.

To start Chalkfy at login, add it in System Settings > General > Login Items.

## Shortcuts

- ⌃⌥H: Highlight on or off, a ring that follows the cursor.
- ⌃⌥L: Laser on or off. Drag to draw a red stroke that fades by itself. Esc also turns it off.

## Firefox-based browsers

A screen share from Firefox, Zen or another Firefox-based browser does not show Chalkfy. Workaround: in `about:config`, set `media.getdisplaymedia.screencapturekit.picker.enabled` to `false` and restart the browser. On macOS 15 this brings back repeated permission prompts.
