//
//  WindowManager.swift
//  TouchDock
//
//  Updated on 2025‑07‑19
//

import Cocoa
import OSLog

/// Manages which screen the TouchDock panel lives on,
/// watches for display re‑configuration events,
/// and re‑locates the panel accordingly.
final class WindowManager {

    // MARK: Singleton
    static let shared = WindowManager()
    private init() {
        startObservingDisplayChanges()
    }

    // MARK: Public API
    private(set) var currentScreen: NSScreen?
    private var dockWindow: TouchBarWindow?

    /// Call from AppDelegate once at launch.
    func setupDockWindow() {
        currentScreen = preferredScreen()
        guard let screen = currentScreen else { return }

        dockWindow = TouchBarWindow(screen: screen, edge: .bottom)
        dockWindow?.makeKeyAndOrderFront(nil)
    }

    /// Toggle visibility (for global hot‑key).
    func toggleVisibility() {
        guard let window = dockWindow else { return }
        window.isVisible ? window.orderOut(nil) : window.orderFront(nil)
    }

    // MARK: Internals
    /// Pick a screen to host the dock ― iPad/Sidecar first, else main display.
    private func preferredScreen() -> NSScreen? {
        let screens = NSScreen.screens

        // iPad (Sidecar / Luna) detection – fall back to main
        if let ipad = screens.first(where: { $0.localizedName.contains("iPad") }) {
            return ipad
        }
        return NSScreen.main ?? screens.first
    }

    /// Re-evaluate screens and move the dock when a configuration change occurs.
    private func refreshScreens() {
        let next = preferredScreen()
        guard next != currentScreen else { return }

        currentScreen = next
        relocateDock()
        log.debug("Display change detected – dock moved to \(next?.localizedName ?? "nil").")
    }

    /// Physically move the NSPanel to `currentScreen`.
    private func relocateDock() {
        guard let screen = currentScreen, let win = dockWindow else { return }
        win.move(to: screen, edge: .bottom)          // `.bottom` is the default edge for now
    }
}

// MARK: – Display change observers
private extension WindowManager {

    func startObservingDisplayChanges() {

        // High‑level notification (most cases).
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in
                self?.refreshScreens()
        }

        // Low‑level callback catches GPU / AirPlay / Sidecar events.
        CGDisplayRegisterReconfigurationCallback({ _, _, _ in
            DispatchQueue.main.async {
                WindowManager.shared.refreshScreens()
            }
        }, nil)
    }
}

// MARK: – Logger
private extension WindowManager {
    /// Static logger for this subsystem.
    static let log = Logger(subsystem: "com.example.TouchDock",
                            category: "window-manager")
    var log: Logger { Self.log }
}
