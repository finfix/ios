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
    @Environment(AppSettings.self) var appSettings
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
                Button {
                    modelData.sync()
                } label: {
                    Text("Синхронизировать")
                }
                .frame(maxWidth: .infinity)
            }
            Section {
                Button {
                    isLogin = false
                    accessToken = nil
                    refreshToken = nil
                } label: {
                    Text("Выйти")
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    Profile()
        .environment(ModelData())
        .environment(AppSettings())
}
