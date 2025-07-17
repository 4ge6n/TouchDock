

import Foundation

/// TouchDock プラグイン用プロトコル
public protocol TouchDockPlugin {
    var pluginName: String { get }
    func onLoad()
    func onUnload()
    // ここに Dock カスタマイズ等のAPIを追加
}

/// サンプル実装例
public final class SamplePlugin: TouchDockPlugin {
    public let pluginName = "SamplePlugin"
    public init() {}
    public func onLoad() {
        // プラグイン読み込み時の処理
    }
    public func onUnload() {
        // プラグイン解放時の処理
    }
}
