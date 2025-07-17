import Foundation
import AppKit

struct BarPreset: Codable {
    var name: String
    var dockItems: [DockItem]

    struct DockItem: Codable {
        var name: String            // 表示名
        var iconName: String        // AppKitで使う画像名 or Assets.xcassets名
        var bundleID: String?       // アプリ起動時（launchApp用のみ必須）
        var actionType: String?     // "launchApp", "keystroke", "applescript", "shell"
        var actionValue: String?    // コマンド/スクリプト内容・キーなど

        // 互換性: 旧プリセットとの互換性維持のため、デコード時にactionType/bundleIDの自動補完も今後検討
    }
}
