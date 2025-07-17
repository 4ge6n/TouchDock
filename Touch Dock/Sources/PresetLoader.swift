import Foundation

class PresetLoader {
    static func loadPreset(named name: String) -> BarPreset? {
        // アプリバンドルの Resources/Presets/name.json を読む
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Presets") else {
            Logger.shared.error("PresetLoader: ファイルが見つかりません: \(name).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let preset = try JSONDecoder().decode(BarPreset.self, from: data)
            Logger.shared.log("PresetLoader: プリセット読込成功: \(name)")
            return preset
        } catch {
            Logger.shared.error("PresetLoader: デコード失敗: \(error)")
            return nil
        }
    }
}
