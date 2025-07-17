import Foundation

/// TouchDock プラグイン管理クラス
class PluginManager {
    private(set) var loadedPlugins: [TouchDockPlugin] = []
    
    /// Plugins ディレクトリ内の .bundle を動的ロード
    func loadPlugins() {
        loadedPlugins.removeAll()
        let fm = FileManager.default
        let pluginsDir = Bundle.main.bundleURL.appendingPathComponent("Plugins")
        guard let bundlePaths = try? fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil, options: [])
            .filter({ $0.pathExtension == "bundle" }) else { return }
        
        for path in bundlePaths {
            if let bundle = Bundle(url: path),
               let principal = bundle.principalClass as? TouchDockPlugin.Type {
                let plugin = principal.init()
                plugin.onLoad()
                loadedPlugins.append(plugin)
            }
        }
    }
    
    /// 全プラグイン解放
    func unloadPlugins() {
        loadedPlugins.forEach { $0.onUnload() }
        loadedPlugins.removeAll()
    }
}
