import AppKit
import Carbon.HIToolbox
import Core

var chalk = Chalk()
var overlays: [(window: NSWindow, ring: CAShapeLayer, dot: CAShapeLayer, strokes: CALayer)] = []
var primaryHeight: CGFloat = 0
var tap: CFMachPort?

@discardableResult
func handle(_ event: Event) -> Disposition {
    let now = CACurrentMediaTime()
    let disposition = chalk.handle(event, at: now)
    let scene = chalk.scene(at: now)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for overlay in overlays {
        let local = scene.local(in: overlay.window.frame)
        overlay.ring.isHidden = true
        overlay.dot.isHidden = true
        switch local.marker {
        case .ring(let p)?: overlay.ring.position = p; overlay.ring.isHidden = false
        case .dot(let p)?: overlay.dot.position = p; overlay.dot.isHidden = false
        case nil: break
        }
        // Rebuilt on every event: an animation that began in the past resumes mid fade, so no layer needs to be tracked.
        // ponytail: the whole path of every stroke is rebuilt per event, O(n²) over a drag; append to the live layer's path if long drags lag.
        overlay.strokes.sublayers = local.strokes.map { stroke in
            let layer = CAShapeLayer()
            let path = CGMutablePath()
            path.addLines(between: stroke.points)
            layer.path = path
            layer.lineWidth = 4
            layer.lineCap = .round
            layer.lineJoin = .round
            layer.strokeColor = NSColor.systemRed.cgColor
            layer.fillColor = nil
            layer.contentsScale = overlay.window.backingScaleFactor
            if let releasedAt = stroke.releasedAt {
                // The model opacity is the end state, so the stroke stays hidden once the animation is removed.
                layer.opacity = 0
                let fade = CABasicAnimation(keyPath: "opacity")
                fade.fromValue = 1
                fade.toValue = 0
                fade.beginTime = releasedAt
                fade.duration = Stroke.fade
                layer.add(fade, forKey: nil)
            }
            return layer
        }
    }
    CATransaction.commit()
    return disposition
}

func buildOverlays() {
    overlays.forEach { $0.window.orderOut(nil) }
    primaryHeight = NSScreen.screens.first?.frame.height ?? 0
    overlays = NSScreen.screens.map { screen in
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.setFrame(screen.frame, display: false)
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.sharingType = .readOnly
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.contentView = NSView()
        window.contentView!.wantsLayer = true

        let ring = CAShapeLayer()
        ring.path = CGPath(ellipseIn: CGRect(x: -30, y: -30, width: 60, height: 60), transform: nil)
        ring.lineWidth = 3
        ring.strokeColor = NSColor.systemYellow.cgColor
        ring.fillColor = NSColor.systemYellow.withAlphaComponent(0.25).cgColor
        ring.contentsScale = screen.backingScaleFactor
        ring.isHidden = true

        let dot = CAShapeLayer()
        dot.path = CGPath(ellipseIn: CGRect(x: -6, y: -6, width: 12, height: 12), transform: nil)
        dot.fillColor = NSColor.systemRed.cgColor
        dot.contentsScale = screen.backingScaleFactor
        dot.isHidden = true

        let strokes = CALayer()
        [strokes, ring, dot].forEach(window.contentView!.layer!.addSublayer)

        window.orderFrontRegardless()
        return (window, ring, dot, strokes)
    }
    handle(.move(NSEvent.mouseLocation))
}

func startTap() {
    let types: [CGEventType] = [.mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp, .rightMouseDragged, .otherMouseDragged]
    let mask = types.reduce(CGEventMask(0)) { $0 | 1 << $1.rawValue }
    tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, _ in
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        // CGEvent's origin is the top left of the primary display; Core's is its bottom left.
        let p = CGPoint(x: event.location.x, y: primaryHeight - event.location.y)
        let e: Event = switch type {
        case .leftMouseDown: .press(p)
        case .leftMouseDragged: .drag(p)
        case .leftMouseUp: .release(p)
        default: .move(p)
        }
        return handle(e) == .swallow ? nil : Unmanaged.passUnretained(event)
    }, userInfo: nil)
    guard let tap else { return }
    CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
}

final class Actions: NSObject {
    @objc func requestAccessibility() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
    }
}

let app = NSApplication.shared
let actions = Actions()
let menu = NSMenu()
let accessibilityItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
let requestItem = menu.addItem(withTitle: "Request Accessibility Permission", action: #selector(Actions.requestAccessibility), keyEquivalent: "")
requestItem.target = actions
menu.addItem(.separator())
menu.addItem(withTitle: "Quit Chalkfy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
statusItem.button?.image = NSImage(systemSymbolName: "scribble", accessibilityDescription: "Chalkfy")
statusItem.menu = menu

// Polls so the grant applies without a relaunch: there is no notification for it.
func checkAccessibility() {
    let trusted = AXIsProcessTrusted()
    accessibilityItem.title = trusted ? "Accessibility: granted" : "Accessibility: not granted"
    requestItem.isHidden = trusted
    if trusted, tap == nil { startTap() }
    // A revoked grant leaves a dead tap; invalidating it also removes its run loop source, so a re-grant makes a new one.
    if !trusted, let dead = tap {
        CFMachPortInvalidate(dead)
        tap = nil
    }
}
checkAccessibility()
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in checkAccessibility() }

// The id of each hotkey is the index of its event here.
let hotKeyEvents: [Event] = [.toggleHighlight, .toggleLaser, .escape]
func registerHotKey(_ key: Int, modifiers: Int, for event: Event) -> (EventHotKeyRef?, OSStatus) {
    var ref: EventHotKeyRef?
    let id = EventHotKeyID(signature: 0x43484C4B, id: UInt32(hotKeyEvents.firstIndex(of: event)!))
    let status = RegisterEventHotKey(UInt32(key), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
    return (ref, status)
}
func showUnavailable(_ name: String, _ status: OSStatus) {
    menu.insertItem(withTitle: "\(name) unavailable (error \(status))", action: nil, keyEquivalent: "", at: 0)
}
var escKey: EventHotKeyRef?
var escUnavailableShown = false

var hotKeySpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
    var id = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
    guard hotKeyEvents.indices.contains(Int(id.id)) else { return OSStatus(eventNotHandledErr) }
    handle(hotKeyEvents[Int(id.id)])
    // Esc is a hotkey only while the Laser is on, so it reaches other apps otherwise.
    if chalk.laser, escKey == nil {
        let status: OSStatus
        (escKey, status) = registerHotKey(kVK_Escape, modifiers: 0, for: .escape)
        if status != noErr, !escUnavailableShown {
            showUnavailable("Esc", status)
            escUnavailableShown = true
        }
    } else if !chalk.laser, let key = escKey {
        UnregisterEventHotKey(key)
        escKey = nil
    }
    return noErr
}, 1, &hotKeySpec, nil, nil)
for (key, name, event) in [(kVK_ANSI_H, "⌃⌥H", Event.toggleHighlight), (kVK_ANSI_L, "⌃⌥L", .toggleLaser)] {
    let status = handlerStatus != noErr ? handlerStatus : registerHotKey(key, modifiers: controlKey | optionKey, for: event).1
    if status != noErr { showUnavailable(name, status) }
}

buildOverlays()
NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in
    buildOverlays()
}
// Moves the ring without Accessibility; the tap, once granted, reports the same moves again, which is harmless.
NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { _ in
    handle(.move(NSEvent.mouseLocation))
}

app.run()
