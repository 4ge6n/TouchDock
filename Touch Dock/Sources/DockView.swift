import Cocoa

/// Dockのアイコン多段表示ビュー
class DockView: NSView {
    private var stackRows: [NSStackView] = []
    private var engine = LayoutEngine()
    private var apps: [LayoutEngine.DockApp] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        observePrefs() // 追加: UserDefaults監視開始
        refresh()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observePrefs() // 追加: UserDefaults監視開始
        refresh()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        observePrefs() // 追加: awakeFromNibでもUserDefaults監視開始
        refresh()
    }
    deinit {
        NotificationCenter.default.removeObserver(self) // 追加: UserDefaults監視解除
    }

    /// UserDefaults監視
    private func observePrefs() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPrefsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    @objc private func onPrefsChanged(_ note: Notification) {
        refresh()
    }

    /// アプリアイコン一覧をリフレッシュ
    func refresh() {
        // Prefsの透過度反映 追加
        self.alphaValue = Prefs.dockOpacity

        // 一度全削除
        stackRows.forEach { $0.removeFromSuperview() }
        stackRows = []

        // 最新アプリ取得
        apps = engine.fetchDockApps()
        // 多段/1段切り替え 追加
        let multi = Prefs.multiRowEnabled
        let perRow = engine.maxIconsPerRow(windowWidth: bounds.width)
        var rows: [[LayoutEngine.DockApp]]
        if multi {
            rows = engine.splitRows(apps: apps, perRow: perRow)
        } else {
            rows = [apps] // 1段表示
        }

        // スタック行生成
        var prev: NSView? = nil
        for row in rows {
            let stack = NSStackView()
            stack.orientation = .horizontal
            stack.distribution = .fillEqually
            stack.alignment = .centerY
            for app in row {
                let btn = NSButton(image: app.icon, target: self, action: #selector(appButtonClicked(_:)))
                btn.imageScaling = .scaleProportionallyUpOrDown
                btn.bezelStyle = .regularSquare
                btn.title = ""
                btn.identifier = NSUserInterfaceItemIdentifier(app.bundleID)
                btn.setButtonType(.momentaryChange)
                btn.toolTip = app.name // アプリ名をツールチップ
                stack.addArrangedSubview(btn)
            }
            stack.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stack)
            stackRows.append(stack)
            // レイアウト
            if let prev = prev {
                stack.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 8).isActive = true
            } else {
                stack.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
            }
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
            prev = stack
        }

        // コントロールストリップ行（音量・輝度コントロールなど）追加
        let ctrlStack = NSStackView()
        ctrlStack.orientation = .horizontal
        ctrlStack.distribution = .equalSpacing
        ctrlStack.alignment = .centerY
        ctrlStack.spacing = 16

        // 音量-
        let volDownBtn = NSButton(title: "🔉", target: self, action: #selector(volumeDown))
        volDownBtn.toolTip = NSLocalizedString("Volume Down", comment: "")
        ctrlStack.addArrangedSubview(volDownBtn)
        // ミュート
        let muteBtn = NSButton(title: "🔇", target: self, action: #selector(volumeMute))
        muteBtn.toolTip = NSLocalizedString("Mute", comment: "")
        ctrlStack.addArrangedSubview(muteBtn)
        // 音量+
        let volUpBtn = NSButton(title: "🔊", target: self, action: #selector(volumeUp))
        volUpBtn.toolTip = NSLocalizedString("Volume Up", comment: "")
        ctrlStack.addArrangedSubview(volUpBtn)
        // 輝度-
        let brightDownBtn = NSButton(title: "🌙", target: self, action: #selector(brightnessDown))
        brightDownBtn.toolTip = NSLocalizedString("Brightness Down", comment: "")
        ctrlStack.addArrangedSubview(brightDownBtn)
        // 輝度+
        let brightUpBtn = NSButton(title: "💡", target: self, action: #selector(brightnessUp))
        brightUpBtn.toolTip = NSLocalizedString("Brightness Up", comment: "")
        ctrlStack.addArrangedSubview(brightUpBtn)

        ctrlStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ctrlStack)
        if let prev = prev {
            ctrlStack.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 12).isActive = true
        } else {
            ctrlStack.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        }
        ctrlStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24).isActive = true
        ctrlStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24).isActive = true
        ctrlStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
    }

    /// ボタンクリックで該当アプリを前面に or 起動 or プリセットアクション
    @objc private func appButtonClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue,
              let app = apps.first(where: { $0.bundleID == id }) else { return }
        if let runningApp = app.app {
            runningApp.activate(options: [.activateIgnoringOtherApps])
        } else {
            // プリセットDockボタンの場合はBarPreset.DockItemを参照してActionDispatcherへ
            if let enginePreset = engine.preset,
               let item = enginePreset.dockItems.first(where: { $0.bundleID == id }) {
                ActionDispatcher.performAction(for: item)
            } else {
                // 旧互換: bundleIDでアプリ起動
                NSWorkspace.shared.launchApplication(withBundleIdentifier: id, options: [], additionalEventParamDescriptor: nil, launchIdentifier: nil)
            }
        }
    }

    // システム音量・輝度制御
    @objc func volumeUp()   { runAppleScript("set volume output volume (output volume of (get volume settings) + 6)") }
    @objc func volumeDown() { runAppleScript("set volume output volume (output volume of (get volume settings) - 6)") }
    @objc func volumeMute() { runAppleScript("set volume output muted true") }
    @objc func brightnessUp()   { runAppleScript("do shell script \"brightness +0.1\"") }
    @objc func brightnessDown() { runAppleScript("do shell script \"brightness -0.1\"") }

    private func runAppleScript(_ script: String) {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&error)
    }
}
