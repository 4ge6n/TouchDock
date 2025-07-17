import XCTest
@testable import TouchDock
final class LoggerTests: XCTestCase {
    func testLog() {
        Logger.log("Hello")
        XCTAssertEqual(Logger.lastMessage, "Hello")
    }
}
