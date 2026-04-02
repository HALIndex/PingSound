//
//  AppDelegate.swift
//  PingSound
//
//  Central orchestrator: owns all managers, wires callbacks,
//  and coordinates the ping lifecycle.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    let appState = AppState()

    private var deviceMonitor: AudioDeviceMonitor!
    private var pingEngine: SilencePingEngine!
    private var scheduler: PingScheduler!
    private var sleepObserver: SleepWakeObserver!
    private var lastKnownEnabled = true

    // MARK: - Convenience

    private var targetKeywords: [String] {
        UserDefaults.standard.stringArray(forKey: "targetDeviceKeywords") ?? []
    }

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Persist defaults on first run (register(defaults:) only provides
        // in-memory fallback — we want the values on disk so the Devices tab
        // always has data to read).
        let ud = UserDefaults.standard
        if ud.object(forKey: "pingEnabled") == nil {
            ud.set(true, forKey: "pingEnabled")
        }
        if ud.object(forKey: "pingIntervalMinutes") == nil {
            ud.set(8.0, forKey: "pingIntervalMinutes")
        }
        if ud.stringArray(forKey: "targetDeviceKeywords") == nil {
            ud.set(["Acton", "Stanmore", "Woburn"], forKey: "targetDeviceKeywords")
        }

        lastKnownEnabled = appState.isEnabled

        // 1. Audio engine
        pingEngine = SilencePingEngine()

        // 2. Scheduler
        let interval = UserDefaults.standard.double(forKey: "pingIntervalMinutes")
        scheduler = PingScheduler(intervalMinutes: interval > 0 ? interval : 8.0)
        scheduler.onFire = { [weak self] in
            self?.performPing()
        }

        // 3. Device monitor
        deviceMonitor = AudioDeviceMonitor()
        deviceMonitor.onDeviceChanged = { [weak self] deviceName in
            self?.handleDeviceChange(deviceName)
        }

        // 4. Sleep/wake observer
        sleepObserver = SleepWakeObserver()
        sleepObserver.onSleep = { [weak self] in self?.handleSleep() }
        sleepObserver.onWake  = { [weak self] in self?.handleWake()  }

        // 5. Observe UserDefaults for changes from Preferences or SwiftUI Toggle
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.handleDefaultsChanged()
        }

        // 6. Initial device check
        let currentDevice = deviceMonitor.currentOutputDeviceName()
        handleDeviceChange(currentDevice)
    }

    // MARK: - Logic

    private func handleDeviceChange(_ deviceName: String) {
        guard appState.isEnabled else {
            appState.statusText = "⏸ Disabled"
            return
        }

        if deviceMatchesKeywords(deviceName) {
            appState.statusText = "🔊 Active: \(deviceName)"
            scheduler.stop()
            scheduler.start()
            pingEngine.ping()
        } else {
            appState.statusText = "😴 Idle: \(deviceName)"
            scheduler.stop()
            pingEngine.stop()
        }
    }

    private func performPing() {
        guard appState.isEnabled else { return }
        let device = deviceMonitor.currentOutputDeviceName()
        guard deviceMatchesKeywords(device) else { return }
        pingEngine.ping()
    }

    private func handleSleep() {
        scheduler.stop()
        pingEngine.stop()
    }

    private func handleWake() {
        guard appState.isEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            let device = self.deviceMonitor.currentOutputDeviceName()
            self.handleDeviceChange(device)
        }
    }

    private func handleDefaultsChanged() {
        // Handle enable/disable toggle
        let currentEnabled = appState.isEnabled
        if currentEnabled != lastKnownEnabled {
            lastKnownEnabled = currentEnabled
            if currentEnabled {
                let device = deviceMonitor.currentOutputDeviceName()
                handleDeviceChange(device)
            } else {
                scheduler.stop()
                pingEngine.stop()
                appState.statusText = "⏸ Disabled"
            }
        }

        // Handle interval change
        let newInterval = UserDefaults.standard.double(forKey: "pingIntervalMinutes")
        if newInterval > 0 && newInterval != scheduler.intervalMinutes {
            scheduler.intervalMinutes = newInterval
            let device = deviceMonitor.currentOutputDeviceName()
            if appState.isEnabled && deviceMatchesKeywords(device) {
                scheduler.stop()
                scheduler.start()
            }
        }
    }

    // MARK: - Helpers

    private func deviceMatchesKeywords(_ deviceName: String) -> Bool {
        targetKeywords.contains { keyword in
            deviceName.localizedCaseInsensitiveContains(keyword)
        }
    }
}
