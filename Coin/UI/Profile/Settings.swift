//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct Settings: View {
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("basePath") private var basePath: String = defaultBasePath

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
            Section {
                HStack {
                    TextField(text: $basePath) {
                        Text("Кастомный URL")
                    }
                    Button("По умолчанию") {
                        basePath = defaultBasePath
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    Settings()
}
