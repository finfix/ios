//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct Profile: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @AppStorage("basePath") private var basePath: String = defaultBasePath
    @Environment(ModelData.self) var modelData
    @State var isShowHidedAccounts = false
    
    @Environment(\.modelContext) var modelContext
        
    @Query var users: [User]
    
    var user: User {
        if !users.isEmpty {
            return users.first!
        }
        return User()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Имя пользователя: \(user.name)")
                    Text("Email: \(user.email)")
                    Text("Дата регистрации: \(user.timeCreate)")
                }
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
    
    func getUser() {
        if users.isEmpty {
            UserAPI().GetUser() { model, error in
                if let err = error {
                    showErrorAlert(error: err)
                } else if let response = model {
                    modelContext.insert(response)
                }
            }
        }
    }
}

#Preview {
    Profile()
        .environment(ModelData())
}
