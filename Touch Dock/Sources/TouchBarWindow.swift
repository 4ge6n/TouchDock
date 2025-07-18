import Cocoa
import Combine
import SwiftUI   // for PrefsModel

/// Floating panel that represents the on‑screen TouchDock bar.
class TouchBarWindow: NSPanel {

    // MARK: - Properties
    private(set) var edge: Edge
    private let thickness: CGFloat
    private var cancellables = Set<AnyCancellable>()
    private var themeCancellable: AnyCancellable?

    // MARK: - Initialiser
    /// Create a dock window on a specific screen/edge.
    /// - Parameters:
    ///   - screen:   Target display.
    ///   - edge:     Attachment edge.
    ///   - thickness: Height (top/bottom) or width (left/right) of the dock.
    init(screen: NSScreen, edge: Edge = .bottom, thickness: CGFloat = 48) {
        self.edge = edge
        self.thickness = thickness

        let rect = LayoutEngine.frame(for: screen, edge: edge, thickness: thickness)

        super.init(contentRect: rect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false,
                   screen: screen)

        configureWindow()
    }

    // MARK: - Public API
    /// Move dock to another screen/edge.
    func move(to screen: NSScreen, edge: Edge) {
        self.edge = edge
        let newFrame = LayoutEngine.frame(for: screen, edge: edge, thickness: thickness)
        setFrame(newFrame, display: true)
        setFrameOrigin(newFrame.origin)     // Prevent unexpected animation jump
    }

    // MARK: - Mouse Handling
    /// Allow user to drag the panel and snap it to nearby edges.
    override func mouseDragged(with event: NSEvent) {
        // First let the panel follow the cursor
        super.mouseDragged(with: event)
        // Then attempt snapping
        LayoutEngine.snap(window: self)
    }

    // MARK: - Private
    private func configureWindow() {
        isFloatingPanel = true
        hidesOnDeactivate = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = false
        hasShadow = true
        titleVisibility = .hidden

        // Hide standard window buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        bindOpacity()
        bindTheme()
    }

    /// Track DockOpacity (UserDefaults) and apply to window alpha.
    private func bindOpacity() {
        // 初期値
        let val = UserDefaults.standard.double(forKey: "DockOpacity")
        alphaValue = val == 0 ? 1.0 : CGFloat(val)   // デフォルト 1.0

        // UserDefaults 監視
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let v = UserDefaults.standard.double(forKey: "DockOpacity")
            self.alphaValue = v == 0 ? 1.0 : CGFloat(v)
        }
    }

    /// Observes ThemeManager and updates background colour.
    private func bindTheme() {
        // Apply initial theme
        backgroundColor = ThemeManager.shared.current.background

        themeCancellable = ThemeManager.shared.$current
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                self?.backgroundColor = theme.background
            }
    }
}
