//
//  AudioDeviceMonitor.swift
//  PingSound
//
//  Monitors the system's default audio output device using CoreAudio.
//  Notifies via callback when the device changes.
//

import Foundation
import CoreAudio

final class AudioDeviceMonitor {

    var onDeviceChanged: ((String) -> Void)?

    private var listenerBlock: AudioObjectPropertyListenerBlock?

    init() {
        startListening()
    }

    deinit {
        stopListening()
    }

    // MARK: - Public

    /// Returns the name of the current default output audio device.
    func currentOutputDeviceName() -> String {
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        guard status == noErr else { return "Unknown" }
        return nameForDevice(deviceID)
    }

    // MARK: - Private

    private func nameForDevice(_ deviceID: AudioDeviceID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name = [CChar](repeating: 0, count: 256)
        var size = UInt32(name.count)

        let status = AudioObjectGetPropertyData(
            deviceID, &address, 0, nil, &size, &name
        )
        guard status == noErr else { return "Unknown" }
        return String(cString: name)
    }

    private func startListening() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            let name = self.currentOutputDeviceName()
            DispatchQueue.main.async {
                self.onDeviceChanged?(name)
            }
        }
        self.listenerBlock = block

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            block
        )
    }

    private func stopListening() {
        guard let block = listenerBlock else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            block
        )
        listenerBlock = nil
    }
}
