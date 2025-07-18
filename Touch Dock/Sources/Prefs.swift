//
//  Prefs.swift
//  TouchDock
//
//  Created on 2025‑07‑19
//

import SwiftUI
import Combine

// MARK: - UserDefaults Keys
private enum PrefKey {
    static let globalShortcut = "GlobalShortcut"
    static let selectedPreset = "SelectedPreset"
    static let dockOpacity    = "DockOpacity"
    static let multiRow       = "MultiRowEnabled"
}

// MARK: - Observable Settings Model
final class PrefsModel: ObservableObject {

    @AppStorage(PrefKey.globalShortcut)  var globalShortcut: String = ""
    @AppStorage(PrefKey.selectedPreset)  var selectedPreset: String = "default"
    @AppStorage(PrefKey.dockOpacity)     var dockOpacity: Double   = 1.0
    @AppStorage(PrefKey.multiRow)        var multiRow: Bool        = false

    /// All preset filenames found in the bundle & user directory.
    var availablePresets: [String] {
        PresetLoader.shared
            .presetURL(for: "")?          // ask loader for directory
            .deletingLastPathComponent()  // base Presets dir
            .allPresetNames               // quick extension below
            ?? ["default"]
    }

    /// Available theme names from ThemeManager
    var availableThemes: [String] {
        ThemeManager.all.map { $0.name }
    }

    @Published var selectedTheme: String = ThemeManager.shared.current.name
}

// MARK: - Prefs View
struct PrefsView: View {

    @StateObject private var prefs = PrefsModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Preset picker
            Picker("Preset", selection: $prefs.selectedPreset) {
                ForEach(prefs.availablePresets, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .onChange(of: prefs.selectedPreset) { new in
                PresetLoader.shared.setPreset(named: new)
            }

            // Theme picker
            Picker("Theme", selection: $prefs.selectedTheme) {
                ForEach(prefs.availableThemes, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .onChange(of: prefs.selectedTheme) { new in
                ThemeManager.shared.selectTheme(named: new)
            }

            // Opacity slider
            HStack {
                Text("Opacity")
                Slider(value: $prefs.dockOpacity, in: 0.3...1.0, step: 0.05)
                Text(String(format: "%.0f%%", prefs.dockOpacity * 100))
                    .frame(width: 50, alignment: .trailing)
            }

            // Multi‑row toggle
            Toggle("Enable multi‑row dock", isOn: $prefs.multiRow)

            // Global shortcut (simple text field for now)
            HStack {
                Text("Global shortcut:")
                TextField("⌘⌥J", text: $prefs.globalShortcut)
                    .frame(width: 80)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 320)
    }
}

// MARK: - Window controller helper
final class PrefsWindowController {

    static let shared = PrefsWindowController()
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PrefsView()
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "Preferences"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.isReleasedWhenClosed = false
        win.center()
        win.setFrameAutosaveName("PrefsWindow")
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = win
    }
}

// MARK: - URL helper to enumerate presets
private extension URL {
    var allPresetNames: [String] {
        (try? FileManager.default.contentsOfDirectory(at: self,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles))
        ?.filter { $0.pathExtension == "json" }
        .map { $0.deletingPathExtension().lastPathComponent }
        ?? []
    }
}
