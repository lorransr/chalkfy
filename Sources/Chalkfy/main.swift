import AppKit
import Carbon.HIToolbox
import Core

var chalk = Chalk()
var overlays: [(window: NSWindow, ring: CAShapeLayer)] = []
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
        if case .ring(let p)? = scene.local(in: overlay.window.frame).marker {
            overlay.ring.position = p
            overlay.ring.isHidden = false
        } else {
            overlay.ring.isHidden = true
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
        window.contentView!.layer!.addSublayer(ring)

        window.orderFrontRegardless()
        return (window, ring)
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

var hotKeySpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
    handle(.toggleHighlight)
    return noErr
}, 1, &hotKeySpec, nil, nil)
var hotKey: EventHotKeyRef?
let hotKeyStatus = RegisterEventHotKey(UInt32(kVK_ANSI_H), UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x43484C4B, id: 1),
                                        GetApplicationEventTarget(), 0, &hotKey)
if let error = [handlerStatus, hotKeyStatus].first(where: { $0 != noErr }) {
    menu.insertItem(withTitle: "⌃⌥H unavailable (error \(error))", action: nil, keyEquivalent: "", at: 0)
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
