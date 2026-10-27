# Pointerly vs Cluxo: modes, settings, default shortcuts

Answers #3. Checked 2026-10-27.

Sources:
- Pointerly (closed source, Mac App Store, $3.99, macOS 15+, v1.5.0): [site + FAQ](https://pointerly.app/), [App Store version history](https://apps.apple.com/us/app/pointerly/id6736710502), [changelog](https://pointerly.featurebase.app/changelog). There are no public docs, so settings beyond the ones listed below are unknown until someone installs the app.
- Cluxo (MIT, macOS 13+, v1.5.1, `brew install --cask kykim79/tap/cluxo`): [kykim79/Cluxo](https://github.com/kykim79/Cluxo) at `ab7197e`. Defaults come from `Sources/Cluxo/CursorSettings.swift` and keys from `KeyboardHotkeyHandler.swift`. Where the README and the code disagree, the code wins.

## Modes

| Mode | Pointerly | Cluxo |
|---|---|---|
| Cursor highlight | "Mouse Highlight" toggle. Styles: default and Comet (animated trail, 1.3.0) | Ring is always on (menu bar "Disable" switches the whole app off). Shapes: circle, squircle, diamond, hexagon. Sizes 36/54/72/xl pt. Fades out after 3 s idle and pulses once at 1.5 s idle |
| Click effect | Part of Mouse Highlight. Clicks "stand out", no details published | Fires on release by default: the ring shrinks on press and springs back on release (alt style: tilt). Right click is the mirror image. With release mode off, clicks fire on press instead: ripple (left), double ripple (right), burst (double click), arcs (middle). Drag stretches the ring, scroll shows arrows |
| Spotlight | Dims the background around the cursor. Edge-softness setting (1.3.0) | Dims at black 0.78 opacity outside a cutout around the cursor, with fade in/out. The cutout follows the ring shape. Radius 130 pt, feather 0.4 |
| Laser pointer | Temporary highlight that leaves no marks | None (closest are cursor trail and comet streak, both off by default) |
| Whiteboard / draw | Draws on screen. Undo/redo, remembers last tool and color, optional persistence across sessions (1.4.0), text tool (1.5.0), one shortcut per tool. The site mock shows highlighter, arrow, circle and pen, with green, yellow, blue, purple and red | Modifier-driven tools: drag = pen, Shift = line, Opt = arrow, Cmd = rect, Cmd+Shift = ellipse, Cmd+Opt = highlighter, Shift+Opt+click = numbered badge. Cmd+Z undoes, `[` `]` set thickness (5 steps), Esc clears and exits. Color follows the ring color |
| Magnifier | None | 1.5x to 4x lens around the cursor (default 2x, 200 pt). Needs Screen Recording permission |
| Extras | None | Keystroke overlay (off), shake to find cursor (on), radial menu, coordinate inspector, trackpad gesture labels (off, private API), Cmd+V clipboard toast, screenshot mode |

## Default shortcuts

| Action | Pointerly | Cluxo |
|---|---|---|
| Highlight | ⌥H | always on |
| Laser | ⌥L | none |
| Spotlight | ⌥S | ⌃⌥S |
| Draw | ⌥W | ⌃⌥D |
| Magnifier | none | ⌃⌥M, zoom ⌃⌥= / ⌃⌥- |
| Keystrokes | none | ⌃⌥K |
| Ring color | none | ⌃⌥1-7 (yellow, red, blue, green, cyan, purple, white), cycle ⌃⌥C |
| Ring shape | none | ⌃⌥H cycles |
| Radial menu | none | ⌃⌥, (also middle click by default, or long-press, or 3-finger tap) |
| Inspector | none | ⌃⌥I |

Rebinding: Pointerly allows any combination (Settings > General). Cluxo keeps ⌃⌥ fixed and only lets you change the letter for spotlight, keystroke, magnifier, radial, draw and inspector.

## Settings beyond the tables

- Pointerly: spotlight edge softness, highlighter style, whiteboard persistence. Nothing else is published.
- Cluxo: 8 color slots including a custom one (default cyan), opacity, border weight and style (solid, dashed, dotted), fill (none, gradient, radial ticks), glow and its intensity, animation speed, drag-stretch intensity, scroll indicator, trail mode, shake sensitivity, keystroke timeout (3 s), keystroke auto-on when an unknown monitor connects, launch at login, UI language.

## Permissions

Cluxo needs Accessibility and Input Monitoring, plus Screen Recording for the magnifier only. Its overlay uses `sharingType = .none` so the magnifier does not capture itself, which also hides the overlay from screen capture until you turn on "screenshot mode". Pointerly does not document what it needs.
