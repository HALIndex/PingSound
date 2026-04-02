//
//  SilencePingEngine.swift
//  PingSound
//
//  Generates and plays a ~0.1s silent audio buffer via AVAudioEngine.
//  Does NOT register with Now Playing / MPRemoteCommandCenter,
//  so media keys remain unaffected.
//

import AVFoundation

final class SilencePingEngine {

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let silentBuffer: AVAudioPCMBuffer
    private var isSetup = false

    init() {
        let sampleRate: Double = 44100
        let frameCount: AVAudioFrameCount = 4410 // 0.1 seconds
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        // Buffer data is zero-initialized → pure silence
        self.silentBuffer = buffer
    }

    // MARK: - Lifecycle

    private func setupIfNeeded() {
        guard !isSetup else { return }
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: silentBuffer.format)
        isSetup = true
    }

    func start() {
        setupIfNeeded()
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            print("[PingSound] Audio engine started")
        } catch {
            print("[PingSound] Audio engine start error: \(error)")
        }
    }

    func stop() {
        guard engine.isRunning else { return }
        playerNode.stop()
        engine.stop()
        print("[PingSound] Audio engine stopped")
    }

    /// Schedule and play one silent ping.
    func ping() {
        start()
        guard engine.isRunning else { return }
        playerNode.scheduleBuffer(silentBuffer)
        if !playerNode.isPlaying {
            playerNode.play()
        }
        print("[PingSound] Silent ping sent")
    }
}
