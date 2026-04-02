//
//  SettingsView.swift
//  PingSound
//
//  SwiftUI preferences window with General and Devices tabs.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralTab()
            }
            Tab("Devices", systemImage: "hifispeaker.2") {
                DevicesTab()
            }
            Tab("About", systemImage: "info.circle") {
                AboutTab()
            }
        }
        .frame(width: 460, height: 320)
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage("pingIntervalMinutes") private var pingInterval: Double = 8.0

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[PingSound] Login item error: \(error)")
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section {
                Stepper(
                    "Ping Interval: \(Int(pingInterval)) minutes",
                    value: $pingInterval,
                    in: 1...30,
                    step: 1
                )

                Text("Plays a silent audio ping at the specified interval to keep your Bluetooth speaker awake.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Devices Tab

struct DevicesTab: View {
    @State private var keywords: [String] = []
    @State private var newKeyword = ""
    @State private var showingAddSheet = false
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Device Keywords")
                .font(.headline)

            Text("PingSound activates only when the current audio output device name contains one of these keywords (case-insensitive).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            List(selection: $selection) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                }
                .onDelete(perform: deleteKeyword)
            }
            .listStyle(.bordered)

            HStack {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 14, height: 14)
                }
                .help("Add Keyword")

                Button {
                    if let sel = selection, let idx = keywords.firstIndex(of: sel) {
                        deleteKeyword(at: IndexSet(integer: idx))
                        selection = nil
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 14, height: 14)
                }
                .disabled(selection == nil)
                .help("Remove Selected Keyword")

                Spacer()

                Button("Reset to Defaults") {
                    keywords = ["Acton", "Stanmore", "Woburn"]
                    saveKeywords()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear { loadKeywords() }
        .sheet(isPresented: $showingAddSheet) {
            addKeywordSheet
        }
    }

    // MARK: - Add Sheet

    private var addKeywordSheet: some View {
        VStack(spacing: 16) {
            Text("Add Device Keyword")
                .font(.headline)

            TextField("e.g. Marshall, JBL, Bose", text: $newKeyword)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            HStack(spacing: 12) {
                Button("Cancel") {
                    newKeyword = ""
                    showingAddSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    let trimmed = newKeyword.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && !keywords.contains(trimmed) {
                        keywords.append(trimmed)
                        saveKeywords()
                    }
                    newKeyword = ""
                    showingAddSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    // MARK: - Persistence

    private func loadKeywords() {
        keywords = UserDefaults.standard.stringArray(forKey: "targetDeviceKeywords") ?? []
    }

    private func saveKeywords() {
        UserDefaults.standard.set(keywords, forKey: "targetDeviceKeywords")
    }

    private func deleteKeyword(at offsets: IndexSet) {
        keywords.remove(atOffsets: offsets)
        saveKeywords()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "infinity")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundStyle(.tint)
            
            VStack(spacing: 4) {
                Text("PingSound")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version \(appVersion)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("A lightweight utility to prevent Bluetooth speakers from entering deep sleep.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Link("View on GitHub", destination: URL(string: "https://github.com/HALIndex/PingSound")!)
                .buttonStyle(.link)
                .padding(.bottom)
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
