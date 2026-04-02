//
//  PingSoundApp.swift
//  PingSound
//
//  Menu-bar-only app using SwiftUI MenuBarExtra + SettingsLink.
//

import SwiftUI

@main
struct PingSoundApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu()
                .environment(appDelegate.appState)
        } label: {
            Image(systemName: "infinity")
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Menu Bar Menu

struct MenuBarMenu: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var state = appState

        Text(appState.statusText)

        Divider()

        Toggle("Enable PingSound", isOn: $state.isEnabled)

        Divider()

        Button("Preferences…") {
            openSettings()
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit PingSound") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
