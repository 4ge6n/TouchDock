import Foundation
struct Prefs {
    static var globalShortcut: String {
        get { UserDefaults.standard.string(forKey: "GlobalShortcut") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "GlobalShortcut") }
    }
}
