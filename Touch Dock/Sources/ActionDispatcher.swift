//
//  ActionDispatcher.swift
//  Touch Dock
//
//  Created by 重村奨斗 on 2025/07/18.
//



import Foundation
import AppKit
import SwiftUI     // for NSAlert helper

class ActionDispatcher {
    /// Show an error alert on the main thread.
    private static func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = title
            alert.informativeText = message
            alert.runModal()
        }
    }

    static func performAction(for item: BarPreset.DockItem) {
        let actionType = item.actionType ?? "launchApp"
        Logger.shared.log("ActionDispatcher: 実行開始: \(actionType) \(item.name)")
        switch actionType {
        case "launchApp":
            if let bundleID = item.bundleID {
                let result = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, options: [], additionalEventParamDescriptor: nil, launchIdentifier: nil)
                if result {
                    Logger.shared.log("ActionDispatcher: アプリ起動成功: \(bundleID)")
                } else {
                    Logger.shared.error("ActionDispatcher: アプリ起動失敗: \(bundleID)")
                }
            } else {
                Logger.shared.error("ActionDispatcher: launchAppにbundleIDがありません: \(item.name)")
            }
        case "keystroke":
            if let key = item.actionValue {
                Logger.shared.log("ActionDispatcher: キーストローク送信: \(key)")
                sendKeystroke(key)
            } else {
                Logger.shared.error("ActionDispatcher: keystrokeにactionValueがありません: \(item.name)")
            }
        case "applescript":
            if let script = item.actionValue {
                Logger.shared.log("ActionDispatcher: AppleScript実行: \(script.prefix(64))...")
                runAppleScript(script)
            } else {
                Logger.shared.error("ActionDispatcher: applescriptにactionValueがありません: \(item.name)")
            }
        case "shell":
            if let cmd = item.actionValue {
                Logger.shared.log("ActionDispatcher: シェルコマンド実行: \(cmd)")
                runShell(cmd)
            } else {
                Logger.shared.error("ActionDispatcher: shellにactionValueがありません: \(item.name)")
            }
        default:
            Logger.shared.error("ActionDispatcher: 未知のactionType: \(actionType)")
        }
    }

    /// Send a key (with optional modifiers) such as "cmd+shift+4" or "ctrl+alt+return".
    private static func sendKeystroke(_ combo: String) {
        let parts = combo.split(separator: "+").map { $0.lowercased() }

        guard let keyPart = parts.last,
              let keycode = keyToKeyCode(String(keyPart)) else {
            Logger.shared.error("ActionDispatcher: 未知のキー: \(combo)")
            showAlert(title: "Invalid Keystroke", message: "Unknown key in '\(combo)'.")
            return
        }

        // Modifier flags
        var flags: CGEventFlags = []
        for tok in parts.dropLast() {
            switch tok {
            case "cmd", "command":   flags.insert(.maskCommand)
            case "alt", "option":    flags.insert(.maskAlternate)
            case "ctrl", "control":  flags.insert(.maskControl)
            case "shift":            flags.insert(.maskShift)
            default:
                Logger.shared.error("ActionDispatcher: 未知のモディファイア: \(tok)")
            }
        }

        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keycode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: keycode, keyDown: false)
        down?.flags = flags
        up?.flags   = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    /// Map common keys / digits to CGKeyCode
    private static func keyToKeyCode(_ key: String) -> CGKeyCode? {
        // alphabets
        if let ascii = key.unicodeScalars.first?.value,
           ascii >= 97 && ascii <= 122 {           // a–z
            return CGKeyCode(ascii - 97)
        }
        // digits 0–9
        if let d = Int(key), (0...9).contains(d) {
            return CGKeyCode(29 + d)               // kVK_ANSI_0 is 29
        }
        switch key {
        case "return", "enter": return 36          // kVK_Return
        case "space":           return 49          // kVK_Space
        case "escape", "esc":   return 53          // kVK_Escape
        case "tab":             return 48          // kVK_Tab
        default: return nil
        }
    }

    private static func runAppleScript(_ script: String) {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        if let error = error {
            Logger.shared.error("ActionDispatcher: AppleScriptエラー: \(error)")
            showAlert(title: "AppleScript Error", message: error.description)
        }
    }

    private static func runShell(_ cmd: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", cmd]
        do {
            let pipe = Pipe()
            task.standardError = pipe
            task.standardOutput = pipe
            try task.run()
            Logger.shared.log("ActionDispatcher: シェルコマンド起動: \(cmd)")
        } catch {
            Logger.shared.error("ActionDispatcher: シェルコマンド起動失敗: \(error)")
            showAlert(title: "Shell Command Error", message: error.localizedDescription)
        }
    }
}
