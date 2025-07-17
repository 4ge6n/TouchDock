import Foundation
class Logger {
    static var lastMessage = ""
    static func log(_ msg: String) {
        lastMessage = msg
        print("[LOG] \(msg)")
    }
}
