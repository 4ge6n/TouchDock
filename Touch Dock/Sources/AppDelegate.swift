import Cocoa
import MASShortcut

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var prefsPanel: NSPanel?
    var screenshotShortcutView: MASShortcutView?
    var engine = LayoutEngine()
    var dockView: DockView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        registerDefaultShortcuts()
        createMainWindow()
        bindShortcuts()

        // プリセットをロードし、engineにセット
        if let preset = PresetLoader.loadPreset(named: "default") {
            engine.preset = preset
        }

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

    private func bindShortcuts() {
        MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: "GlobalShortcut") { [weak self] in
            guard let win = self?.window else { return }
            if win.isVisible { win.orderOut(nil) } else { win.makeKeyAndOrderFront(nil) }
        }
        MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: "GlobalScreenshotShortcut") { [weak self] in
            guard let win = self?.window else { return }
            ScreenshotManager.shared.capture(window: win)
        }
    }

    private func registerDefaultShortcuts() {
        let defaults = UserDefaults.standard
        let def = MASShortcut(keyCode: UInt(kVK_ANSI_T),
                              modifierFlags: [.control, .option, .command])
        let defShot = MASShortcut(keyCode: UInt(kVK_ANSI_S),
                                  modifierFlags: [.control, .option, .command])
        defaults.register(defaults: [
            "GlobalShortcut": def?.data() as Any,
            "GlobalScreenshotShortcut": defShot?.data() as Any
        ])
    }

    // 環境設定ウィンドウ表示
    @objc func showPreferencesWindow() {
        if let panel = prefsPanel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 370),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = NSLocalizedString("Preferences", comment: "")

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 370))

        // Dock位置
        let posLabel = NSTextField(labelWithString: NSLocalizedString("Dock位置:", comment: ""))
        posLabel.frame = NSRect(x: 20, y: 300, width: 80, height: 24)
        content.addSubview(posLabel)
        let posPop = NSPopUpButton(frame: NSRect(x: 110, y: 300, width: 120, height: 24))
        posPop.addItems(withTitles: [NSLocalizedString("下", comment: ""), NSLocalizedString("上", comment: ""), NSLocalizedString("左", comment: ""), NSLocalizedString("右", comment: "")])
        posPop.selectItem(at: Prefs.dockPosition)
        posPop.target = self
        posPop.action = #selector(updateDockPosition(_:))
        content.addSubview(posPop)

        // スライドアニメ
        let slideLabel = NSTextField(labelWithString: NSLocalizedString("スライドアニメ:", comment: ""))
        slideLabel.frame = NSRect(x: 20, y: 260, width: 90, height: 24)
        content.addSubview(slideLabel)
        let slideBtn = NSButton(checkboxWithTitle: NSLocalizedString("有効", comment: ""), target: self, action: #selector(toggleSlideAnim(_:)))
        slideBtn.frame = NSRect(x: 110, y: 260, width: 60, height: 24)
        slideBtn.state = Prefs.slideAnimation ? .on : .off
        content.addSubview(slideBtn)

        // 多段表示
        let multiLabel = NSTextField(labelWithString: NSLocalizedString("多段表示:", comment: ""))
        multiLabel.frame = NSRect(x: 20, y: 220, width: 80, height: 24)
        content.addSubview(multiLabel)
        let multiBtn = NSButton(checkboxWithTitle: NSLocalizedString("ON", comment: ""), target: self, action: #selector(toggleMultiRow(_:)))
        multiBtn.frame = NSRect(x: 110, y: 220, width: 60, height: 24)
        multiBtn.state = Prefs.multiRowEnabled ? .on : .off
        content.addSubview(multiBtn)

        // 透過度
        let opacityLabel = NSTextField(labelWithString: NSLocalizedString("Dock透過度:", comment: ""))
        opacityLabel.frame = NSRect(x: 20, y: 180, width: 100, height: 24)
        content.addSubview(opacityLabel)
        let opacitySlider = NSSlider(value: Prefs.dockOpacity, minValue: 0.2, maxValue: 1.0, target: self, action: #selector(changeOpacity(_:)))
        opacitySlider.frame = NSRect(x: 110, y: 180, width: 180, height: 24)
        content.addSubview(opacitySlider)

        // スクリーンショットモード
        let shotLabel = NSTextField(labelWithString: NSLocalizedString("スクリーンショット:", comment: ""))
        shotLabel.frame = NSRect(x: 20, y: 140, width: 120, height: 24)
        content.addSubview(shotLabel)
        let shotPop = NSPopUpButton(frame: NSRect(x: 140, y: 140, width: 100, height: 24))
        shotPop.addItems(withTitles: [NSLocalizedString("ファイル", comment: ""), NSLocalizedString("クリップボード", comment: ""), NSLocalizedString("両方", comment: "")])
        shotPop.selectItem(at: Prefs.screenshotMode)
        shotPop.target = self
        shotPop.action = #selector(changeScreenshotMode(_:))
        content.addSubview(shotPop)

        // グローバルショートカット(ダミー表示) 削除

        // スクリーンショットショートカット
        let shotShortcutLabel = NSTextField(labelWithString: NSLocalizedString("スクリーンショットホットキー:", comment: ""))
        shotShortcutLabel.frame = NSRect(x: 20, y: 60, width: 170, height: 24)
        content.addSubview(shotShortcutLabel)

        let shotShortcutView = MASShortcutView(frame: NSRect(x: 200, y: 60, width: 180, height: 24))
        shotShortcutView.associatedUserDefaultsKey = "GlobalScreenshotShortcut"
        shotShortcutView.shortcutValueChange = { [weak self] _ in
            self?.bindShortcuts()
        }
        content.addSubview(shotShortcutView)
        self.screenshotShortcutView = shotShortcutView

        panel.contentView = content
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        self.prefsPanel = panel
    }

    @objc func updateDockPosition(_ sender: NSPopUpButton) {
        Prefs.dockPosition = sender.indexOfSelectedItem
    }
    @objc func toggleSlideAnim(_ sender: NSButton) {
        Prefs.slideAnimation = (sender.state == .on)
    }
    @objc func toggleMultiRow(_ sender: NSButton) {
        Prefs.multiRowEnabled = (sender.state == .on)
    }
    @objc func changeOpacity(_ sender: NSSlider) {
        Prefs.dockOpacity = sender.doubleValue
    }
    @objc func changeScreenshotMode(_ sender: NSPopUpButton) {
        Prefs.screenshotMode = sender.indexOfSelectedItem
    }
}
