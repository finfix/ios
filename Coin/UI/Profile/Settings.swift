//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct Settings: View {
    
    @Environment(AlertManager.self) var alert
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @Environment(PathSharedState.self) var path
        
    @State private var vm = SettingsViewModel()
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isDarkMode) {
                    Label("Темная тема", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(.primary)
                }
            }
            Section(footer:
                VStack {
                    Text("Version \(vm.appVersion) (Build \(vm.appBuildNumber))")
                    Text("Server version \(vm.serverVersion) (Build \(vm.serverBuildNumber))")
                }
                .frame(maxWidth: .infinity)
            ) {}
        }
        .task {
            do {
                try await vm.load()
            } catch {
                
            }
        }
    }
}

#Preview {
    Settings()
        .environment(AlertManager(handle: {_ in }))
}
