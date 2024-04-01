//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct Settings: View {
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    
    func getAppVersion() -> String {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return "Unknown"
    }

    func getBuildNumber() -> String {
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return buildNumber
        }
        return "Unknown"
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isDarkMode) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        Text("Темная тема")
                    }
                }
            }
            Section(footer: HStack {
                Text("Version \(getAppVersion()) (Build \(getBuildNumber()))")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }) {}
        }
    }
}

#Preview {
    Settings()
}
