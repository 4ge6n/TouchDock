import Cocoa

enum ScreenshotMode: Int {
    case file, clipboard, both
}

class ScreenshotManager {
    static let shared = ScreenshotManager()
    
    // ユーザ設定から取得（0:ファイル, 1:クリップボード, 2:両方）
    var mode: ScreenshotMode {
        get {
            let raw = UserDefaults.standard.integer(forKey: "ScreenshotMode")
            return ScreenshotMode(rawValue: raw) ?? .file
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "ScreenshotMode")
        }
    }
    
    /// TouchDockウィンドウのスクリーンショットを撮る
    func capture(window: NSWindow) {
        guard let contentView = window.contentView else { return }
        let bounds = contentView.bounds
        guard let rep = contentView.bitmapImageRepForCachingDisplay(in: bounds) else { return }
        contentView.cacheDisplay(in: bounds, to: rep)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        switch mode {
        case .file:
            saveToFile(image: nsImage)
        case .clipboard:
            copyToClipboard(image: nsImage)
        case .both:
            saveToFile(image: nsImage)
            copyToClipboard(image: nsImage)
        }
    }
    
    /// 画像をファイルに保存（デスクトップ直下, PNG形式）
    private func saveToFile(image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let filename = desktop.appendingPathComponent("TouchDock_\(dateString()).png")
        try? png.write(to: filename)
    }
    
    /// 画像をクリップボードにコピー
    private func copyToClipboard(image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
    
    /// タイムスタンプ
    private func dateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd_HHmmss"
        return fmt.string(from: Date())
    }
}
