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

//
//  PresetLoader.swift
//  TouchDock
//
//  Updated: 2025‑07‑19
//

import Cocoa
import Combine
import OSLog

/// Loads a JSON preset from the bundle *or* the user's Application Support folder,
/// watches the file for changes, and publishes the decoded `BarPreset`.
///
/// Usage:
/// ```swift
/// PresetLoader.shared.$currentPreset
///     .sink { DockView.shared.update(with: $0) }
///     .store(in: &cancellables)
/// ```
final class PresetLoader: ObservableObject {

    // MARK: – Public
    static let shared = PresetLoader()
    @Published private(set) var currentPreset: BarPreset?

    /// Currently watched preset filename (without ".json")
    private(set) var presetName: String = "default" {
        didSet { reloadPreset() }
    }

    // MARK: – Private
    private var fsSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var cancellables = Set<AnyCancellable>()
    private let log = Logger(subsystem: "com.example.TouchDock", category: "PresetLoader")

    private init() {
        reloadPreset()
        startWatching()
    }

    deinit {
        stopWatching()
    }

    // MARK: – Public API
    /// Change the active preset (e.g. from Prefs panel)
    func setPreset(named name: String) {
        presetName = name
    }

    // MARK: – Loading
    private func reloadPreset() {
        guard let url = presetURL(for: presetName) else {
            log.error("Preset '\(presetName)' not found.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let preset = try JSONDecoder().decode(BarPreset.self, from: data)
            DispatchQueue.main.async {
                self.currentPreset = preset
                self.log.debug("Preset '\(self.presetName, privacy: .public)' loaded.")
            }
        } catch {
            log.error("Failed to decode preset '\(presetName)': \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: – File‑system watching
    private func startWatching() {
        guard let url = presetURL(for: presetName) else { return }
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            log.error("Cannot open preset for watching.")
            return
        }

        fsSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor,
                                                             eventMask: .write,
                                                             queue: .main)
        fsSource?.setEventHandler { [weak self] in
            self?.log.debug("Preset file changed on disk – reloading.")
            self?.reloadPreset()
        }
        fsSource?.resume()
    }

    private func stopWatching() {
        fsSource?.cancel()
        fsSource = nil
        if fileDescriptor >= 0 { close(fileDescriptor) }
        fileDescriptor = -1
    }

    // MARK: – Helpers
    /// Search order: `~/Library/Application Support/TouchDock/Presets/` → app bundle.
    private func presetURL(for name: String) -> URL? {
        // 1) User override
        let userDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("TouchDock/Presets")
        if let u = userDir?.appendingPathComponent("\(name).json"), FileManager.default.fileExists(atPath: u.path) {
            return u
        }

        // 2) Bundle fallback
        return Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Presets")
    }
}
