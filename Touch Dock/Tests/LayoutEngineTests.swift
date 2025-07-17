


import XCTest
@testable import TouchDock

final class LayoutEngineTests: XCTestCase {
    func testMaxIconsPerRow() {
        let engine = LayoutEngine()
        XCTAssertEqual(engine.maxIconsPerRow(windowWidth: 320), 5)
        XCTAssertEqual(engine.maxIconsPerRow(windowWidth: 128), 2)
        XCTAssertEqual(engine.maxIconsPerRow(windowWidth: 60), 1)
    }

    func testSplitRows() {
        let engine = LayoutEngine()
        // ダミーDockApp10個
        let dummyApps = (0..<10).map { i in
            LayoutEngine.DockApp(app: NSRunningApplication(processIdentifier: 0)!)
        }
        let split = engine.splitRows(apps: dummyApps, perRow: 4)
        XCTAssertEqual(split.count, 3)
        XCTAssertEqual(split[0].count, 4)
        XCTAssertEqual(split[1].count, 4)
        XCTAssertEqual(split[2].count, 2)
    }
}
