//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct Settings: View {
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("isDevMode") private var isDevMode = defaultIsDevMode
    @AppStorage("apiBasePath") private var apiBasePath = defaultApiBasePath
    
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
                    Label("Темная тема", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(.primary)
                }
            }
            Section(header: Text("Инструменты разработчика")) {
                Toggle(isOn: $isDevMode) {
                    Label("Режим разработчика", systemImage: "hammer.fill")
                        .foregroundColor(.primary)
                }
                if isDevMode {
                    HStack {
                        TextField("", text: $apiBasePath)
                        Button { apiBasePath = defaultApiBasePath } label: { Text("По умолчанию") }
                    }
                }
            }
            Section(footer:
                Text("Version \(getAppVersion()) (Build \(getBuildNumber()))")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            ) {}
        }
    }
}

#Preview {
    Settings()
}
