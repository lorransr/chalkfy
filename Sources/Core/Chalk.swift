import CoreGraphics

/// Points are global desktop coordinates in Cocoa's convention: origin at the bottom left of the primary display, y up.
public enum Event: Equatable {
    case toggleHighlight, toggleLaser, escape
    case move(CGPoint), press(CGPoint), drag(CGPoint), release(CGPoint)
}

public enum Disposition: Equatable { case pass, swallow }

public enum Marker: Equatable {
    case ring(CGPoint), dot(CGPoint)

    func offset(by origin: CGPoint) -> Marker {
        switch self {
        case .ring(let p): .ring(p.offset(by: origin))
        case .dot(let p): .dot(p.offset(by: origin))
        }
    }
}

public struct Stroke: Equatable {
    public static let fade = 2.0

    public var points: [CGPoint]
    /// Nil while the drag goes on; the fade runs from here for `fade` seconds.
    public var releasedAt: Double?

    public init(points: [CGPoint], releasedAt: Double? = nil) {
        self.points = points
        self.releasedAt = releasedAt
    }

    func visible(at time: Double) -> Bool {
        releasedAt.map { time - $0 < Stroke.fade } ?? true
    }
}

public struct Scene: Equatable {
    public var marker: Marker?
    public var strokes: [Stroke] = []

    public func local(in frame: CGRect) -> Scene {
        Scene(marker: marker?.offset(by: frame.origin),
              strokes: strokes.map { Stroke(points: $0.points.map { $0.offset(by: frame.origin) }, releasedAt: $0.releasedAt) })
    }
}

public struct Chalk {
    var highlight = false
    public private(set) var laser = false
    var cursor = CGPoint.zero
    var strokes: [Stroke] = []
    var drawing: Stroke?

    public init() {}

    @discardableResult
    public mutating func handle(_ event: Event, at time: Double) -> Disposition {
        strokes.removeAll { !$0.visible(at: time) }
        switch event {
        case .toggleHighlight:
            highlight.toggle()
            return .swallow
        case .toggleLaser:
            setLaser(!laser, at: time)
            return .swallow
        case .escape:
            guard laser else { return .pass }
            setLaser(false, at: time)
            return .swallow
        case .move(let p):
            cursor = p
            return .pass
        case .press(let p):
            cursor = p
            guard laser else { return .pass }
            drawing = Stroke(points: [p])
            return .swallow
        case .drag(let p):
            cursor = p
            guard laser else { return .pass }
            drawing?.points.append(p)
            return .swallow
        case .release(let p):
            cursor = p
            guard laser else { return .pass }
            endStroke(at: time)
            return .swallow
        }
    }

    mutating func setLaser(_ on: Bool, at time: Double) {
        laser = on
        // A stroke cut short by Laser off fades like a released one.
        if !on { endStroke(at: time) }
    }

    mutating func endStroke(at time: Double) {
        guard var stroke = drawing else { return }
        stroke.releasedAt = time
        strokes.append(stroke)
        drawing = nil
    }

    public func scene(at time: Double) -> Scene {
        Scene(marker: laser ? .dot(cursor) : highlight ? .ring(cursor) : nil,
              strokes: strokes.filter { $0.visible(at: time) } + (drawing.map { [$0] } ?? []))
    }
}

extension CGPoint {
    func offset(by origin: CGPoint) -> CGPoint { CGPoint(x: x - origin.x, y: y - origin.y) }
}
