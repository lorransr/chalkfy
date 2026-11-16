# Settings in UserDefaults, as presets in the menu bar

## Context

The presenter adjusts the Settings (#33) and expects them to survive a relaunch and a `brew upgrade`.

## Decision

Each Setting is a submenu of presets in the menu bar. The app keeps the picked value in `UserDefaults`, under the raw value of `Setting` in `Sources/Chalkfy/main.swift`.

## Reason

`UserDefaults` lives in `~/Library/Preferences` under the bundle id, outside the `.app` that `brew upgrade` replaces. A rename of a raw value makes the app forget the presenter's pick, with no warning. To rename a key, read the old key once and write its value to the new key.

## Rejected

- A slider in the menu: every pixel of a drag would rebuild the overlay windows, and the screen would flicker.
- A preferences window: one more window to keep for four values.
