//
//  SleepWakeObserver.swift
//  PingSound
//
//  Observes macOS system sleep/wake notifications to pause and resume
//  the ping mechanism. Never holds a wake assertion.
//

import Foundation
import AppKit

final class SleepWakeObserver {

    var onSleep: (() -> Void)?
    var onWake: (() -> Void)?

    private var sleepToken: (any NSObjectProtocol)?
    private var wakeToken: (any NSObjectProtocol)?

    init() {
        let nc = NSWorkspace.shared.notificationCenter

        sleepToken = nc.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[PingSound] System will sleep")
            self?.onSleep?()
        }

        wakeToken = nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[PingSound] System did wake")
            self?.onWake?()
        }
    }

    deinit {
        let nc = NSWorkspace.shared.notificationCenter
        if let sleepToken { nc.removeObserver(sleepToken) }
        if let wakeToken  { nc.removeObserver(wakeToken)  }
    }
}
