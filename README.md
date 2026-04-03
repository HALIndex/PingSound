# PingSound ♾️

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 5](https://img.shields.io/badge/Swift-5-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

**PingSound** is a lightweight, strictly menu-bar macOS utility designed to solve a specific, frustrating problem: **Bluetooth speakers (like Marshall Acton III, etc.) going into deep sleep or disconnecting automatically** when no audio is played for a certain period of time.

It prevents this by continuously playing a completely inaudible "silent ping" (0.1 seconds of empty buffer) in the background at a customizable interval, keeping your speakers awake and seamlessly connected.

## ✨ Features

- **Smart Output Detection**: PingSound monitors your macOS default audio output device. It will *only* send keep-alive pings when the current audio device matches the keywords you define (e.g., "Acton" or "Stanmore"). If you switch back to your Mac's internal speakers, the app intelligently suspends itself.
- **Inaudible & Invisible**: The keep-alive ping is a purely zeroed-out `AVAudioPCMBuffer` played through `AVAudioEngine`. It's completely silent.
- **Media Keys Friendly**: Unlike naive implementations, PingSound does **not** hijack your Mac's "Now Playing" control center. Your keyboard media keys will continue to control Spotify, Apple Music, or YouTube without interruption.
- **App Nap Resistant**: Uses a high-precision `DispatchSourceTimer` with a `.strict` flag to completely bypass macOS App Nap timer coalescing, ensuring your interval strictly fires precisely when intended.
- **Sleep & Wake Aware**: Observes system sleep state (`NSWorkspace.willSleepNotification`). When you close your MacBook lid, PingSound pauses the engine so it never holds a wake lock or drains your battery.
- **Launch at Login**: Easily configurable to start automatically in the standard macOS login items (`SMAppService`).

## 🛠 Installation & Build

PingSound is built natively in Swift using AppKit, SwiftUI, AVFoundation, and CoreAudio.

1. Clone this repository.
2. Open `PingSound.xcodeproj` in **Xcode**.
3. Select your Mac as the destination.
4. Hit **`Cmd + R`** (Build and Run).

## 🎛 Usage

Upon launching, PingSound will appear discreetly in your menu bar (as a small infinity icon) and will automatically check your current audio device. 

### Preferences (`Cmd + ,`)
Click the menu bar icon and select **Preferences...**

- **General Tab**: 
  - Toggle "Launch at Login".
  - Configure the **Ping Interval**. (Default is 8 minutes, which is optimal for Marshall speakers that usually sleep after 10-15 minutes).
  
- **Devices Tab**: 
  - Here you can manage your "Target Device Keywords". 
  - Add partial names of your Bluetooth devices (e.g., `Acton`, `JBL`, `Bose`).
  - PingSound performs a case-insensitive check against the active audio device name. If it finds a match, the scheduler turns on!

## ⚙️ Requirements

- **macOS 26.0** or newer.
- Xcode 26+ for building the project.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
