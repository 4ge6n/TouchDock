

import Foundation

class Logger {
    static let shared = Logger()
    private let logFileURL: URL

    private init() {
        let logDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        logFileURL = logDir.appendingPathComponent("TouchDock.log")
    }

    func log(_ message: String) {
        write("INFO: \(timestamp()) \(message)")
    }

    func error(_ message: String) {
        write("ERROR: \(timestamp()) \(message)")
    }

    private func write(_ line: String) {
        print(line)
        if let data = (line + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fh = try? FileHandle(forWritingTo: logFileURL) {
                    fh.seekToEndOfFile()
                    fh.write(data)
                    try? fh.close()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }

    private func timestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: Date())
    }
}
