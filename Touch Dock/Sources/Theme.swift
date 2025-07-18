

//
//  Theme.swift
//  TouchDock
//
//  Created on 2025-07-19
//

import AppKit
import Combine

/// Simple colour theme definition for the dock UI.
struct Theme {
    let name: String
    let background: NSColor
    let buttonTint: NSColor
}

/// Singleton that holds the currently‑selected theme and broadcasts changes.
final class ThemeManager: ObservableObject {

    // MARK: Static themes
    static let light = Theme(
        name: "Light",
        background: NSColor.windowBackgroundColor,
        buttonTint: NSColor.labelColor)

    static let dark = Theme(
        name: "Dark",
        background: NSColor.black,
        buttonTint: NSColor.white)

    /// Later: read custom themes from JSON / asset catalog
    static let all: [Theme] = [light, dark]

    // MARK: Published selection
    static let shared = ThemeManager()
    @Published var current: Theme

    private init() {
        // Default to system appearance
        current = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua]) == .darkAqua
            ? Self.dark
            : Self.light
    }

    /// Select by name (called from Prefs picker)
    func selectTheme(named name: String) {
        if let found = Self.all.first(where: { $0.name == name }) {
            current = found
        }
    }
}
