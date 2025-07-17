

import XCTest
@testable import TouchDock

final class WindowManagerTests: XCTestCase {
    func testFrameCalculation() {
        let manager = WindowManager()
        let testScreen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        manager.window.setFrame(NSRect(origin: .zero, size: NSSize(width: 800, height: 100)), display: false)

        // 下
        manager.dockPosition = 0
        let frame0 = manager.window.frame
        XCTAssertEqual(frame0.origin.y, testScreen.minY, accuracy: 2)
        // 上
        manager.dockPosition = 1
        let frame1 = manager.window.frame
        XCTAssertEqual(frame1.origin.y, testScreen.maxY - frame1.height, accuracy: 2)
        // 左
        manager.dockPosition = 2
        let frame2 = manager.window.frame
        XCTAssertEqual(frame2.origin.x, testScreen.minX, accuracy: 2)
        // 右
        manager.dockPosition = 3
        let frame3 = manager.window.frame
        XCTAssertEqual(frame3.origin.x, testScreen.maxX - frame3.width, accuracy: 2)
    }
}
