import Cocoa
import Combine
import SwiftUI               // PrefsModel
import Carbon.HIToolbox       // key codes

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private var globalHotKeyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private let prefs = PrefsModel()
    var engine = LayoutEngine()
    var dockView: DockView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        createMainWindow()

        // Observe globalShortcut changes
        prefs.$globalShortcut
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.registerGlobalShortcut() }
            .store(in: &cancellables)

        registerGlobalShortcut()

        // Engine preset
        PresetLoader.shared.$currentPreset
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.engine.preset = $0
                self?.dockView.refresh()
            }
            .store(in: &cancellables)

        // DockView生成しウィンドウにセット
        dockView = DockView(frame: window.contentView!.bounds, engine: engine)
        window.contentView = dockView
        dockView.refresh()
    }

    private func setupMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu

        // Appメニュー
        let appMenu = NSMenu()
        // Preferences
        appMenu.addItem(withTitle: NSLocalizedString("Preferences", comment: ""), action: #selector(showPreferencesWindow), keyEquivalent: ",")
        // Quit
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: NSLocalizedString("Quit TouchDock", comment: ""), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
    }

    private func createMainWindow() {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        window = NSWindow(
            contentRect: NSRect(x: screen.midX-200, y: screen.midY-150, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false)
        window.title = NSLocalizedString("TouchDock", comment: "")
        window.makeKeyAndOrderFront(nil)
    }

    @objc func showPreferencesWindow() {
        PrefsWindowController.shared.show()
    }

    /// Register / re‑register the global hot‑key defined in PrefsModel.
    /// For now we only recognise ⌘⌥J; other strings fall back to that.
    private func registerGlobalShortcut() {
        // Remove old
        if let monitor = globalHotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // Parse shortcut – accept "⌘⌥J" or default
        let combo = prefs.globalShortcut.isEmpty ? "⌘⌥J" : prefs.globalShortcut
        guard combo == "⌘⌥J" else { return }        // simplistic parser

        globalHotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] evt in
            if evt.modifierFlags.contains([.command, .option]) && evt.keyCode == kVK_ANSI_J {
                guard let win = self?.window else { return }
                win.isVisible ? win.orderOut(nil) : win.makeKeyAndOrderFront(nil)
            }
        }
    }
}
