import CoreGraphics
import Core
import Testing

@Test func highlightTogglesAndFollowsTheCursor() {
    var chalk = Chalk()
    #expect(chalk.scene(at: 0).marker == nil)

    chalk.handle(.toggleHighlight, at: 1)
    #expect(chalk.handle(.move(CGPoint(x: 10, y: 20)), at: 2) == .pass)
    #expect(chalk.scene(at: 2).marker == .ring(CGPoint(x: 10, y: 20)))
    #expect(chalk.handle(.press(CGPoint(x: 30, y: 40)), at: 3) == .pass)
    #expect(chalk.handle(.release(CGPoint(x: 30, y: 40)), at: 3) == .pass)
    #expect(chalk.scene(at: 3).marker == .ring(CGPoint(x: 30, y: 40)))

    chalk.handle(.toggleHighlight, at: 4)
    #expect(chalk.scene(at: 4).marker == nil)
}

@Test func sceneConvertsToEachDisplay() {
    var chalk = Chalk()
    chalk.handle(.toggleHighlight, at: 0)
    chalk.handle(.move(CGPoint(x: -1000, y: 1500)), at: 0)
    let scene = chalk.scene(at: 0)

    // A second display to the left of and above the primary one.
    #expect(scene.local(in: CGRect(x: -1920, y: 1080, width: 1920, height: 1080)).marker == .ring(CGPoint(x: 920, y: 420)))
    #expect(scene.local(in: CGRect(x: 0, y: 0, width: 1512, height: 982)).marker == .ring(CGPoint(x: -1000, y: 1500)))
}

@Test func laserTogglesIndependentlyAndItsDotHidesTheRing() {
    var chalk = Chalk()
    let p = CGPoint(x: 5, y: 5)
    chalk.handle(.move(p), at: 0)
    chalk.handle(.toggleLaser, at: 0)
    #expect(chalk.scene(at: 0).marker == .dot(p))

    chalk.handle(.toggleHighlight, at: 1)
    #expect(chalk.scene(at: 1).marker == .dot(p))
    chalk.handle(.toggleLaser, at: 2)
    #expect(chalk.scene(at: 2).marker == .ring(p))
    chalk.handle(.toggleLaser, at: 3)
    chalk.handle(.toggleHighlight, at: 3)
    #expect(chalk.scene(at: 3).marker == .dot(p))
}

@Test func escapeTurnsTheLaserOffAndPassesOtherwise() {
    var chalk = Chalk()
    #expect(chalk.handle(.escape, at: 0) == .pass)
    chalk.handle(.toggleLaser, at: 1)
    #expect(chalk.handle(.escape, at: 2) == .swallow)
    #expect(chalk.scene(at: 2).marker == nil)
    #expect(chalk.handle(.escape, at: 3) == .pass)
}

@Test func laserSwallowsTheDragButNotTheMove() {
    var chalk = Chalk()
    let p = CGPoint(x: 1, y: 2)
    chalk.handle(.toggleLaser, at: 0)
    #expect(chalk.handle(.move(p), at: 1) == .pass)
    #expect(chalk.handle(.press(p), at: 1) == .swallow)
    #expect(chalk.handle(.drag(p), at: 1) == .swallow)
    #expect(chalk.handle(.release(p), at: 1) == .swallow)

    chalk.handle(.toggleLaser, at: 1)
    #expect(chalk.handle(.press(p), at: 2) == .pass)
    #expect(chalk.handle(.drag(p), at: 2) == .pass)
    #expect(chalk.handle(.release(p), at: 2) == .pass)
    #expect(chalk.scene(at: 2).strokes.count == 1)
}

@Test func eachStrokeFadesTwoSecondsAfterItsRelease() {
    var chalk = Chalk()
    let a = CGPoint(x: 0, y: 0), b = CGPoint(x: 10, y: 0)
    chalk.handle(.toggleLaser, at: 0)
    chalk.handle(.press(a), at: 0)
    chalk.handle(.drag(b), at: 0.5)
    #expect(chalk.scene(at: 10).strokes == [Stroke(points: [a, b])])
    chalk.handle(.release(b), at: 1)

    chalk.handle(.press(b), at: 2)
    chalk.handle(.drag(a), at: 2)
    // Laser off mid drag ends the second stroke; both keep fading.
    chalk.handle(.toggleLaser, at: 2.5)
    chalk.handle(.drag(b), at: 2.6)

    #expect(chalk.scene(at: 2.9).strokes == [Stroke(points: [a, b], releasedAt: 1), Stroke(points: [b, a], releasedAt: 2.5)])
    #expect(chalk.scene(at: 3).strokes == [Stroke(points: [b, a], releasedAt: 2.5)])
    chalk.handle(.move(a), at: 4.4)
    #expect(chalk.scene(at: 4.4).strokes.count == 1)
    #expect(chalk.scene(at: 4.5).strokes.isEmpty)
}

@Test func aStrokeAcrossADisplayEdgeShowsOnBoth() {
    var chalk = Chalk()
    chalk.handle(.toggleLaser, at: 0)
    chalk.handle(.press(CGPoint(x: -10, y: 0)), at: 0)
    chalk.handle(.drag(CGPoint(x: 10, y: 0)), at: 0)
    let scene = chalk.scene(at: 0)

    let left = scene.local(in: CGRect(x: -1920, y: 0, width: 1920, height: 1080))
    let right = scene.local(in: CGRect(x: 0, y: 0, width: 1512, height: 982))
    #expect(left.strokes.map(\.points) == [[CGPoint(x: 1910, y: 0), CGPoint(x: 1930, y: 0)]])
    #expect(right.strokes.map(\.points) == [[CGPoint(x: -10, y: 0), CGPoint(x: 10, y: 0)]])
}
