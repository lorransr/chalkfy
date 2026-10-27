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
