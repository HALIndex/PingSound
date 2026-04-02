//
//  AppState.swift
//  PingSound
//
//  Shared observable state between AppDelegate (logic) and SwiftUI (UI).
//

import Foundation

@Observable
final class AppState {
    var statusText = "Initializing…"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "pingEnabled")
        }
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "pingEnabled")
    }
}
