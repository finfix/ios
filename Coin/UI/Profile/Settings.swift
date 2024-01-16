//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct Settings: View {
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode

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
        }
    }
}

#Preview {
    Settings()
}
