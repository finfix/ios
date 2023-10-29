//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Profile: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @AppStorage("basePath") private var basePath: String = defaultBasePath
    @Environment(ModelData.self) var modelData
    @State var isShowHidedAccounts = false
    
    var body: some View {
        NavigationStack {
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
                    Button("Скрытые счета") {
                        isShowHidedAccounts = true
                    }
                    .navigationDestination(isPresented: $isShowHidedAccounts) {
                        HidedAccountsList()
                    }
                }
                .frame(maxWidth: .infinity)
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
                Section {
                    Button("Выйти") {
                        isLogin = false
                        accessToken = nil
                        refreshToken = nil
                        modelData.deleteAllData()
                    }
                    .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    Profile()
        .environment(ModelData())
}
