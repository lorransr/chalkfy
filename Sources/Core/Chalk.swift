import CoreGraphics

/// Points are global desktop coordinates in Cocoa's convention: origin at the bottom left of the primary display, y up.
public enum Event: Equatable {
    case toggleHighlight
    case move(CGPoint), press(CGPoint), drag(CGPoint), release(CGPoint)
}

public enum Disposition: Equatable { case pass, swallow }

public enum Marker: Equatable {
    case ring(CGPoint)

    func offset(by origin: CGPoint) -> Marker {
        switch self {
        case .ring(let p): .ring(CGPoint(x: p.x - origin.x, y: p.y - origin.y))
        }
    }
}

public struct Scene: Equatable {
    public var marker: Marker?

    public func local(in frame: CGRect) -> Scene {
        Scene(marker: marker?.offset(by: frame.origin))
    }
}

public struct Chalk {
    var highlight = false
    var cursor = CGPoint.zero

    public init() {}

    @discardableResult
    public mutating func handle(_ event: Event, at time: Double) -> Disposition {
        switch event {
        case .toggleHighlight:
            highlight.toggle()
            return .swallow
        case .move(let p), .press(let p), .drag(let p), .release(let p):
            cursor = p
            return .pass
        }
    }

    public func scene(at time: Double) -> Scene {
        Scene(marker: highlight ? .ring(cursor) : nil)
    }
}
