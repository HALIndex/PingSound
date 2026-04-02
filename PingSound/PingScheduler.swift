//
//  PingScheduler.swift
//  PingSound
//
//  High-precision GCD timer with `.strict` flag to defeat App Nap
//  timer coalescing. Fires on a utility queue, dispatches callback to main.
//

import Foundation

final class PingScheduler {

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "fish.boom.pingsound.scheduler", qos: .utility)

    var intervalMinutes: Double
    var onFire: (() -> Void)?

    init(intervalMinutes: Double = 8.0) {
        self.intervalMinutes = intervalMinutes
    }

    deinit {
        cancel()
    }

    // MARK: - Control

    func start() {
        cancel()

        let t = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        let intervalSeconds = intervalMinutes * 60.0
        t.schedule(
            deadline: .now() + intervalSeconds,
            repeating: intervalSeconds,
            leeway: .seconds(1)
        )

        let handler = self.onFire
        t.setEventHandler {
            DispatchQueue.main.async {
                handler?()
            }
        }

        t.resume()
        timer = t
        print("[PingSound] Scheduler started — interval: \(intervalMinutes) min")
    }

    func stop() {
        cancel()
        print("[PingSound] Scheduler stopped")
    }

    private func cancel() {
        timer?.cancel()
        timer = nil
    }
}
