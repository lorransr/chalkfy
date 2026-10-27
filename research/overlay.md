# Overlay, cursor effects and global shortcuts in Cluxo and CursorX

Answers [#2](https://github.com/lorransr/chalkfy/issues/2). Sources were read on 2026-10-27:

- Cluxo: [kykim79/Cluxo@ab7197e](https://github.com/kykim79/Cluxo/tree/ab7197eb50fd3dbbfaa22374853d3dde284cd72a) (the `kykim79/tap/cluxo` cask). Swift/AppKit with SwiftUI views, deployment target macOS 13.0, not sandboxed, hardened runtime.
- CursorX: [luckrnx09/CursorX@e1236f8](https://github.com/luckrnx09/CursorX/tree/e1236f8d8c2d53d66acbee1901511289cca486c1). This is **Electron 30 + React**, not native Swift, so it shows only the Electron route.

Cluxo links are relative to `Sources/Cluxo/` at the commit above. CursorX links are relative to `src/main/`.

## Overlay window

| | Cluxo ([OverlayWindowController.swift#L18-L33](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/OverlayWindowController.swift#L18-L33)) | CursorX ([core/OverlayManager.ts#L66-L97](https://github.com/luckrnx09/CursorX/blob/e1236f8d8c2d53d66acbee1901511289cca486c1/src/main/core/OverlayManager.ts#L66-L97)) |
|---|---|---|
| Window | borderless `NSWindow`, `contentRect: screen.frame`, clear background, `isOpaque = false`, no shadow | `BrowserWindow`, `transparent`, `frame: false`, `focusable: false`, `fullscreen` |
| Level | `CGWindowLevelForKey(.screenSaverWindow) + 1` | `setAlwaysOnTop(true, 'screen-saver')` |
| Spaces / full screen | `[.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]` | `setVisibleOnAllWorkspaces(true, {visibleOnFullScreen: true})` |
| Click-through | `ignoresMouseEvents = true` | `setIgnoreMouseEvents(true, {forward: true})` |
| All displays | one window per `NSScreen.screens`, rebuilt on `NSApplication.didChangeScreenParametersNotification` ([AppDelegate.swift#L141-L146](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/AppDelegate.swift#L141-L146), [#L1056-L1067](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/AppDelegate.swift#L1056-L1067)) | one window per `screen.getAllDisplays()`, rebuilt on `display-added/removed/metrics-changed` and on `powerMonitor` resume/unlock |
| Content | `NSHostingView` holding SwiftUI. Effects use `Canvas`, and a ~60 fps `Timer` drives the animation phase. | React DOM with CSS animation |
| Agent app | `LSUIElement` + `.accessory` activation policy | `app.dock.hide()` |

**Screen-share gotcha.** By default Cluxo sets `sharingType = .none`. This keeps its own magnifier from capturing the overlay, but it also hides every effect from screen recording and screen sharing. A "screenshot mode" switches it to `.readOnly`. A presenter tool needs the effects visible in a Zoom/Meet share, so chalkfy should keep the default `.readOnly` and exclude its own windows from its own capture with `SCContentFilter(display:excludingApplications:)`. Cluxo already does that for the magnifier ([MagnifierCaptureService.swift#L170-L177](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/MagnifierCaptureService.swift#L170-L177)).

## Mouse input

- **Cluxo** uses `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap)` for moves, button down/up, drags and scroll ([MouseEventMonitor.swift#L133-L155](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/MouseEventMonitor.swift#L133-L155)). The tap runs on its own thread with its own `CFRunLoop`. It re-enables itself on `.tapDisabledByTimeout`/`.tapDisabledByUserInput` and hops to the main thread for UI work.
  - The overlay never accepts clicks. Drawing mode and the radial menu work by **returning `nil` from the tap**, which swallows the event. Only an active (`.defaultTap`) tap can do that ([CGEventTapCallBack](https://developer.apple.com/documentation/coregraphics/cgeventtapcallback)).
  - Bug, do not copy: on pass-through the tap returns `Unmanaged.passRetained(event)`. Quinn (Apple DTS) returns the unchanged event *unretained* ([forum 707680](https://developer.apple.com/forums/thread/707680)). Cluxo's keyboard tap does that correctly.
- **CursorX** polls `screen.getCursorScreenPoint()` every 16 ms ([core/CursorTracker.ts#L27-L33](https://github.com/luckrnx09/CursorX/blob/e1236f8d8c2d53d66acbee1901511289cca486c1/src/main/core/CursorTracker.ts#L27-L33)) and sends the position over IPC to the overlay on the display under the cursor. It has **no click detection**, so a highlight circle is its only effect. It needs no permission.

## Global shortcuts

- **Cluxo** uses a second `.defaultTap` event tap on `keyDown/keyUp/flagsChanged` ([KeyboardHotkeyHandler.swift#L14-L19](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/KeyboardHotkeyHandler.swift#L14-L19), [#L98-L107](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/KeyboardHotkeyHandler.swift#L98-L107)). It returns `nil` for its own ⌃⌥ shortcuts so they never reach the focused app. It moved away from `NSEvent.addGlobalMonitorForEvents` because that monitor cannot consume events (Apple docs: "you can only observe the event"). The same tap also feeds the keystroke display.
- **CursorX** has no shortcuts. It only calls `globalShortcut.unregisterAll()` on quit ([main.ts#L297](https://github.com/luckrnx09/CursorX/blob/e1236f8d8c2d53d66acbee1901511289cca486c1/src/main/main.ts#L297)). On macOS, Electron's `globalShortcut` is Carbon `RegisterEventHotKey` ([Chromium global_accelerator_listener_mac.mm](https://source.chromium.org/chromium/chromium/src/+/main:ui/base/accelerators/global_accelerator_listener/global_accelerator_listener_mac.mm)). Electron's docs list a trusted-accessibility requirement only for media keys ([globalShortcut](https://www.electronjs.org/docs/latest/api/global-shortcut)). So `RegisterEventHotKey` is the shortcut route that needs no permission prompt, but it cannot observe or swallow other keys.

## Permissions

| Permission | Who asks | Why | API |
|---|---|---|---|
| Accessibility | Cluxo | both event taps are `.defaultTap`. Cluxo does not request Input Monitoring because Accessibility already covers it ([PermissionsManager.swift#L9-L10](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/PermissionsManager.swift#L9-L10)) | `AXIsProcessTrustedWithOptions` with `kAXTrustedCheckOptionPrompt` |
| Screen Recording | Cluxo | magnifier only (`SCStream`) | `CGPreflight/RequestScreenCaptureAccess`. Cluxo gates these to macOS 14 and falls back to `SCShareableContent.current` on 13, but Apple marks them available from macOS 10.15 |
| Input Monitoring | neither | a `.listenOnly` keyboard tap would need it. For "weird historical reasons" an `NSEvent` global monitor needs Accessibility while a `CGEventTap` needs Input Monitoring, which is "easily available to sandboxed apps, and even apps published on the Mac App Store" (Quinn, [forum 707680](https://developer.apple.com/forums/thread/707680)) | `CGPreflightListenEventAccess` / `CGRequestListenEventAccess` |
| none | CursorX | polling the cursor and showing transparent windows need no TCC grant | — |

Apple's own `CGEventTapCreate` docs only say key events need root or "access for assistive devices". The mapping `.defaultTap` → Accessibility and `.listenOnly` → Input Monitoring comes from DTS forum posts and from Cluxo's comment, not from the reference docs.

## Private SPI in Cluxo (avoid)

- `CGSMainConnectionID`, `CGSGetActiveSpace`, `CGSManagedDisplayGetCurrentSpace`, `CGSCopyManagedDisplaySpaces` through `@_silgen_name`, used to detect Space changes ([AppDelegate.swift#L9-L16](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/AppDelegate.swift#L9-L16)).
- `dlopen` of `MultitouchSupport.framework`, used for trackpad gestures. It is off by default ([MultitouchService.swift#L96-L98](https://github.com/kykim79/Cluxo/blob/ab7197eb50fd3dbbfaa22374853d3dde284cd72a/Sources/Cluxo/MultitouchService.swift#L96-L98)).

## Minimum macOS per API (Apple docs)

| API | macOS |
|---|---|
| `NSWindow.ignoresMouseEvents`, `NSApplication.didChangeScreenParametersNotification` | no minimum listed (legacy AppKit) |
| `CGWindowLevelForKey`, `CGDisplayHideCursor` | 10.0 |
| `CGEvent.tapCreate` | 10.4 |
| `.canJoinAllSpaces`, `NSWindow.sharingType` | 10.5 |
| `.stationary`, `NSEvent.addGlobalMonitorForEvents` / `addLocalMonitorForEvents` | 10.6 |
| `.fullScreenAuxiliary` | 10.7 |
| `AXIsProcessTrustedWithOptions` | 10.9 |
| `CGPreflight/RequestListenEventAccess`, `CGPreflight/RequestScreenCaptureAccess` | 10.15 |
| SwiftUI `Canvas` | 12.0 |
| ScreenCaptureKit `SCStream` | 12.3 |
| `SMAppService` (Cluxo's launch at login) | 13.0 |
