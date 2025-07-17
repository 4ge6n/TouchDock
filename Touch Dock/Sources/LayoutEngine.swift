

import Cocoa

class LayoutEngine {
    /// Dockに表示するアプリ情報
    struct DockApp {
        let app: NSRunningApplication
        var icon: NSImage { app.icon ?? NSImage(size: NSSize(width: 64, height: 64)) }
        var name: String { app.localizedName ?? "?" }
        var bundleID: String { app.bundleIdentifier ?? "" }
    }

    /// 表示すべきDockアプリ一覧を返す
    func fetchDockApps() -> [DockApp] {
        let running = NSWorkspace.shared.runningApplications
        // ユーザーアプリ・Dock表示可能・TouchDock自身は除外
        let myBundle = Bundle.main.bundleIdentifier
        return running.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier != myBundle
        }.map { DockApp(app: $0) }
    }

    /// 画面幅とアイコン数から、1段あたり最大個数を計算（最小幅64px想定）
    func maxIconsPerRow(windowWidth: CGFloat, iconSize: CGFloat = 64) -> Int {
        max(1, Int(windowWidth / iconSize))
    }

    /// 多段分割: [row0, row1] の2次元配列に分割
    func splitRows(apps: [DockApp], perRow: Int) -> [[DockApp]] {
        stride(from: 0, to: apps.count, by: perRow).map { i in
            Array(apps[i..<min(i+perRow, apps.count)])
        }
    }

    /// Dockアイコン一覧のライブ更新用通知登録
    func startAppListObserver(_ callback: @escaping ()->Void) {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { _ in callback() }
        nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { _ in callback() }
    }
}
