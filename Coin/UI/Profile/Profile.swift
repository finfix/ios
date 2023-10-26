//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Profile: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        Form {
            Toggle(isOn: $isDarkMode) {
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    Text("Темная тема")
                }
            }
            Section {
                Button("Синхронизировать") {
                    modelData.sync()
                }
            }
            Section {
                Button("Выйти") {
                    isLogin = false
                    accessToken = nil
                    refreshToken = nil
                }
                .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    Profile()
        .environment(ModelData())
}
