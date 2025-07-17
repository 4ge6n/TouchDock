//
//  ActionDispatcher.swift
//  Touch Dock
//
//  Created by 重村奨斗 on 2025/07/18.
//



import Foundation
import AppKit

class ActionDispatcher {
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

    private static func sendKeystroke(_ key: String) {
        // 例: "a"→aキー, "return"→リターン等（本格運用時はキー定義表・モディファイア対応必須）
        // ここではシンプルな例のみ
        let source = CGEventSource(stateID: .hidSystemState)
        if let k = keyToKeyCode(key) {
            let down = CGEvent(keyboardEventSource: source, virtualKey: k, keyDown: true)
            let up = CGEvent(keyboardEventSource: source, virtualKey: k, keyDown: false)
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        } else {
            Logger.shared.error("ActionDispatcher: 未知のキー: \(key)")
        }
    }

    private static func keyToKeyCode(_ key: String) -> CGKeyCode? {
        // 超簡易: 一部のみ対応
        switch key.lowercased() {
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "return": return 36
        case "space": return 49
        default: return nil
        }
    }

    private static func runAppleScript(_ script: String) {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        if let error = error {
            Logger.shared.error("ActionDispatcher: AppleScriptエラー: \(error)")
        }
    }

    private static func runShell(_ cmd: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", cmd]
        do {
            try task.run()
            Logger.shared.log("ActionDispatcher: シェルコマンド起動: \(cmd)")
        } catch {
            Logger.shared.error("ActionDispatcher: シェルコマンド起動失敗: \(error)")
        }
    }
}
