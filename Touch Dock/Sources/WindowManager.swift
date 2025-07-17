import Cocoa

class WindowManager: NSObject, NSWindowDelegate {
    private(set) var window: NSWindow
    private let defaultSize = NSSize(width: 800, height: 100)
    
    // ドック配置 0=下 1=上 2=左 3=右
    var dockPosition: Int {
        get { UserDefaults.standard.integer(forKey: "DockPosition") }
        set { UserDefaults.standard.set(newValue, forKey: "DockPosition") }
    }
    
    // スライドアニメON/OFF
    var slideAnimation: Bool {
        get { UserDefaults.standard.bool(forKey: "SlideAnimation") }
        set { UserDefaults.standard.set(newValue, forKey: "SlideAnimation") }
    }
    
    // MARK: - 初期化
    override init() {
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: defaultSize),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "TouchDock"
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        super.init()
        window.delegate = self
        setupHoverAutoHide()
        observeScreenChanges()
        positionWindow()
    }
    
    // MARK: - スクリーン端への吸着（マルチディスプレイ/現在のマウス位置優先）
    func positionWindow() {
        let screen = currentScreen()
        let frame = calculateFrame(for: dockPosition, in: screen.visibleFrame)
        window.setFrame(frame, display: true, animate: false)
    }
    
    private func currentScreen() -> NSScreen {
        // マウス位置の画面を優先、なければ main
        let mouse = NSEvent.mouseLocation
        for s in NSScreen.screens {
            if s.frame.contains(mouse) { return s }
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }
    
    private func calculateFrame(for position: Int, in visible: NSRect) -> NSRect {
        let w = window.frame.width, h = window.frame.height
        let centerX = visible.minX + (visible.width - w)/2
        let centerY = visible.minY + (visible.height - h)/2
        switch position {
        case 0: // 下
            return NSRect(x: round(centerX), y: visible.minY, width: w, height: h)
        case 1: // 上
            return NSRect(x: round(centerX), y: visible.maxY - h, width: w, height: h)
        case 2: // 左
            return NSRect(x: visible.minX, y: round(centerY), width: w, height: h)
        case 3: // 右
            return NSRect(x: visible.maxX - w, y: round(centerY), width: w, height: h)
        default:
            return NSRect(x: round(centerX), y: visible.minY, width: w, height: h)
        }
    }
    
    // MARK: - 画面構成/Spaces変更時も自動再配置
    private func observeScreenChanges() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(screenDidChange), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidChange), name: NSWindow.didChangeScreenNotification, object: nil)
    }
    @objc private func screenDidChange(_ note: Notification) {
        positionWindow()
    }
    
    // MARK: - ウィンドウリサイズ時にも吸着維持
    func windowDidResize(_ notification: Notification) {
        positionWindow()
    }
    
    // MARK: - ホバーでスライドイン/アウト
    private func setupHoverAutoHide() {
        guard let contentView = window.contentView else { return }
        window.acceptsMouseMovedEvents = true
        let area = NSTrackingArea(rect: contentView.bounds,
                                  options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                  owner: self,
                                  userInfo: nil)
        contentView.addTrackingArea(area)
    }
    
    override func mouseEntered(with event: NSEvent) {
        slideIn()
    }
    
    override func mouseExited(with event: NSEvent) {
        slideOut()
    }
    
    func slideIn() {
        guard slideAnimation else { return }
        let screen = currentScreen()
        let frame = calculateFrame(for: dockPosition, in: screen.visibleFrame)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            window.animator().setFrame(frame, display: true)
        }
    }
    
    func slideOut() {
        guard slideAnimation else { return }
        let screen = currentScreen()
        var frame = calculateFrame(for: dockPosition, in: screen.visibleFrame)
        switch dockPosition {
        case 0: frame.origin.y -= frame.height      // 下
        case 1: frame.origin.y += frame.height      // 上
        case 2: frame.origin.x -= frame.width       // 左
        case 3: frame.origin.x += frame.width       // 右
        default: frame.origin.y -= frame.height
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            window.animator().setFrame(frame, display: true)
        }
    }
}
