import Cocoa

class LayoutEngine {
    /// Dockに表示するアプリ情報
    struct DockApp {
        let app: NSRunningApplication?
        let icon: NSImage
        let name: String
        let bundleID: String
        // 通常アプリ
        init(app: NSRunningApplication) {
            self.app = app
            self.icon = app.icon ?? NSImage(size: NSSize(width: 64, height: 64))
            self.name = app.localizedName ?? "?"
            self.bundleID = app.bundleIdentifier ?? ""
        }
        // プリセット（BarPreset）カスタムアイテム用
        init(name: String, icon: NSImage, bundleID: String) {
            self.app = nil
            self.icon = icon
            self.name = name
            self.bundleID = bundleID
        }
    }

    /// 外部プリセット（BarPreset）を利用できるように
    var preset: BarPreset?

    /// 表示すべきDockアプリ一覧を返す
    func fetchDockApps() -> [DockApp] {
        if let preset = preset {
            // 仮: preset.dockItems: [BarPreset.DockItem] だと仮定
            return preset.dockItems.map { item in
                DockApp(
                    name: item.name,
                    icon: NSImage(named: item.iconName) ?? NSImage(size: NSSize(width: 64, height: 64)),
                    bundleID: item.bundleID
                )
            }
        } else {
            let running = NSWorkspace.shared.runningApplications
            // ユーザーアプリ・Dock表示可能・TouchDock自身は除外
            let myBundle = Bundle.main.bundleIdentifier
            return running.filter {
                $0.activationPolicy == .regular && $0.bundleIdentifier != myBundle
            }.map { DockApp(app: $0) }
        }
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
// MARK: - Edge & Snap Helpers
/// Screen edge positions the dock can attach to.
enum Edge: String, CaseIterable {
    case top, bottom, left, right
}

extension LayoutEngine {

    /// Calculate the frame for a dock of given thickness on a specific screen edge.
    /// - Parameters:
    ///   - screen: Target `NSScreen`.
    ///   - edge:   Attachment edge.
    ///   - thickness: Height (top/bottom) or width (left/right) of the dock.
    static func frame(for screen: NSScreen,
                      edge: Edge,
                      thickness: CGFloat = 48) -> NSRect {

        let f = screen.frame
        switch edge {
        case .bottom:
            return NSRect(x: f.minX, y: f.minY,
                          width: f.width, height: thickness)
        case .top:
            return NSRect(x: f.minX, y: f.maxY - thickness,
                          width: f.width, height: thickness)
        case .left:
            return NSRect(x: f.minX, y: f.minY,
                          width: thickness, height: f.height)
        case .right:
            return NSRect(x: f.maxX - thickness, y: f.minY,
                          width: thickness, height: f.height)
        }
    }

    /// Return the closest screen edge to the given window if it is within `threshold` points.
    private static func closestEdge(for window: NSWindow,
                                    threshold: CGFloat = 32) -> Edge? {

        guard let screen = window.screen else { return nil }
        let frame = window.frame
        let s = screen.frame

        let distances: [(Edge, CGFloat)] = [
            (.bottom, abs(frame.minY - s.minY)),
            (.top,    abs(frame.maxY - s.maxY)),
            (.left,   abs(frame.minX - s.minX)),
            (.right,  abs(frame.maxX - s.maxX))
        ]
        if let (edge, dist) = distances.min(by: { $0.1 < $1.1 }), dist <= threshold {
            return edge
        }
        return nil
    }

    /// Snap the window to the nearest edge if within threshold distance.
    static func snap(window: NSWindow,
                     threshold: CGFloat = 32,
                     thickness: CGFloat = 48) {

        guard let screen = window.screen,
              let edge = closestEdge(for: window, threshold: threshold) else { return }

        let newFrame = frame(for: screen, edge: edge, thickness: thickness)
        window.setFrame(newFrame, display: true, animate: true)
    }
}
