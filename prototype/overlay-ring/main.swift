// PROTOTYPE, throwaway. Answers https://github.com/lorransr/chalkfy/issues/5
// Overlay per display (Cluxo setup) + cursor ring + Carbon hotkeys. State goes to the HUD and to ring.log.
import AppKit
import Carbon.HIToolbox

setvbuf(stdout, nil, _IOLBF, 0)
func log(_ s: String) { print("\(Date().formatted(date: .omitted, time: .standard))  \(s)") }

final class Overlay {
    let window: NSWindow
    let ring = CAShapeLayer()
    let hud = CATextLayer()

    init(screen: NSScreen, showHUD: Bool) {
        window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.setFrame(screen.frame, display: false)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        let view = NSView()
        view.wantsLayer = true
        window.contentView = view

        ring.path = CGPath(ellipseIn: CGRect(x: -30, y: -30, width: 60, height: 60), transform: nil)
        ring.fillColor = NSColor.systemYellow.withAlphaComponent(0.25).cgColor
        ring.strokeColor = NSColor.systemYellow.cgColor
        ring.lineWidth = 3
        view.layer!.addSublayer(ring)

        hud.isHidden = !showHUD
        hud.frame = CGRect(x: 20, y: 20, width: 900, height: 120)
        hud.fontSize = 14
        hud.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        hud.foregroundColor = NSColor.white.cgColor
        hud.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        hud.contentsScale = screen.backingScaleFactor
        view.layer!.addSublayer(hud)
        window.orderFrontRegardless()
    }
}

var overlays: [Overlay] = []
var ringOn = true
var hiddenFromShare = false
var tap: CFMachPort?
var pollTimer: Timer?
var hotkeyStatus: [String: OSStatus] = [:]
// ⌃⌥L cycles these to check if the window level decides what screen capture includes.
let levels: [(String, NSWindow.Level)] = [("screenSaver+1", NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)),
                                          ("statusBar", .statusBar), ("floating", .floating)]
var levelIndex = 0

func updateHUD() {
    let input = tap != nil ? "event tap (.defaultTap)" : "polling NSEvent.mouseLocation"
    let keys = hotkeyStatus.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value == noErr ? "ok" : "ERR \($0.value)")" }.joined(separator: " ")
    let text = """
    chalkfy PROTOTYPE   screens=\(overlays.count)   AX trusted=\(AXIsProcessTrusted())
    mouse input: \(input)
    level: \(levels[levelIndex].0) = \(levels[levelIndex].1.rawValue)  (⌃⌥L)
    ring: \(ringOn ? "on" : "off")  (⌥H / ⌃⌥H)    share: \(hiddenFromShare ? "HIDDEN (.none)" : "visible (.readOnly)")  (⌃⌥S)
    hotkeys: \(keys)    quit: ⌃⌥Q
    """
    CATransaction.begin(); CATransaction.setDisableActions(true)
    overlays.forEach { $0.hud.string = text }
    CATransaction.commit()
}

func moveRing(click: Bool? = nil) {
    let p = NSEvent.mouseLocation
    CATransaction.begin(); CATransaction.setDisableActions(true)
    for o in overlays {
        let f = o.window.frame
        o.ring.position = CGPoint(x: p.x - f.minX, y: p.y - f.minY)
        if let click { o.ring.fillColor = (click ? NSColor.systemRed : NSColor.systemYellow).withAlphaComponent(0.35).cgColor }
    }
    CATransaction.commit()
}

func apply() {
    for o in overlays {
        o.window.sharingType = hiddenFromShare ? .none : .readOnly
        o.window.level = levels[levelIndex].1
        o.ring.isHidden = !ringOn
    }
    moveRing()
    updateHUD()
}

func rebuild() {
    overlays.forEach { $0.window.orderOut(nil) }
    overlays = NSScreen.screens.enumerated().map { Overlay(screen: $1, showHUD: $0 == 0) }
    log("screens: " + NSScreen.screens.map { "\($0.localizedName) \($0.frame)" }.joined(separator: " | "))
    apply()
}

func startTap() {
    let types: [CGEventType] = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .leftMouseDown, .leftMouseUp]
    let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
    tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                            eventsOfInterest: mask, callback: { _, type, event, _ in
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            log("tap disabled (\(type.rawValue)), re-enabling")
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .leftMouseDown: moveRing(click: true)
        case .leftMouseUp: moveRing(click: false)
        default: moveRing()
        }
        return Unmanaged.passUnretained(event)
    }, userInfo: nil)
    guard let tap else {
        log("event tap: tapCreate returned nil, falling back to polling")
        if pollTimer == nil { pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in moveRing() } }
        return
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    pollTimer?.invalidate(); pollTimer = nil
    log("event tap: created (AX trusted=\(AXIsProcessTrusted()))")
}

func onHotKey(_ id: UInt32) {
    switch id {
    case 1, 2: ringOn.toggle(); log("hotkey \(id == 1 ? "⌥H" : "⌃⌥H"): ring \(ringOn ? "on" : "off")")
    case 3: hiddenFromShare.toggle(); log("hotkey ⌃⌥S: sharingType \(hiddenFromShare ? ".none" : ".readOnly")")
    case 4: log("quit"); NSApp.terminate(nil)
    case 5: levelIndex = (levelIndex + 1) % levels.count; log("hotkey ⌃⌥L: level \(levels[levelIndex].0) = \(levels[levelIndex].1.rawValue)")
    default: break
    }
    apply()
}

func registerHotKeys() {
    var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
        var id = EventHotKeyID()
        GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                          nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
        onHotKey(id.id)
        return noErr
    }, 1, &spec, nil, nil)
    // ⌥H alone checks if an Option-only combo (Pointerly's default style) still registers on this macOS.
    let keys: [(String, Int, Int)] = [("⌥H", kVK_ANSI_H, optionKey), ("⌃⌥H", kVK_ANSI_H, optionKey | controlKey),
                                      ("⌃⌥S", kVK_ANSI_S, optionKey | controlKey), ("⌃⌥Q", kVK_ANSI_Q, optionKey | controlKey),
                                      ("⌃⌥L", kVK_ANSI_L, optionKey | controlKey)]
    for (i, (name, code, mods)) in keys.enumerated() {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(code), UInt32(mods), EventHotKeyID(signature: 0x43484C4B, id: UInt32(i + 1)),
                                         GetApplicationEventTarget(), 0, &ref)
        hotkeyStatus[name] = status
        log("RegisterEventHotKey \(name): status \(status)")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
log("start: macOS \(ProcessInfo.processInfo.operatingSystemVersionString), bundle \(Bundle.main.bundleIdentifier ?? "none")")
log("AX trusted at launch: \(AXIsProcessTrusted())")
_ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)

rebuild()
registerHotKeys()
startTap()
updateHUD()

NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in
    log("screen parameters changed, rebuilding")
    rebuild()
}
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { _ in
    log("active Space changed: overlays onActiveSpace=\(overlays.map { $0.window.isOnActiveSpace }) visible=\(overlays.map { $0.window.isVisible })")
}
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { n in
    let a = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    log("frontmost app: \(a?.localizedName ?? "?")")
}
// Checks if an Accessibility grant takes effect without a relaunch.
var lastTrusted = AXIsProcessTrusted()
Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
    let now = AXIsProcessTrusted()
    guard now != lastTrusted else { return }
    lastTrusted = now
    log("AX trusted changed to \(now)")
    if now, tap == nil { startTap() }
    updateHUD()
}

app.run()
