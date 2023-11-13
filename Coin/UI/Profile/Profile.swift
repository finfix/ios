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
    @State var isShowCurrencyRates = false
    
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
                Section {
                    Toggle(isOn: $isDarkMode) {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            Text("Темная тема")
                        }
                    }
                }
                Section {
                    Button("Синхронизировать") {
                        modelData.sync()
                    }
                    Button("Скрытые счета") {
                        isShowHidedAccounts = true
                    }
                    Button("Курсы валют") {
                        isShowCurrencyRates = true
                    }
                    .navigationDestination(isPresented: $isShowHidedAccounts) {
                        HidedAccountsList()
                    }
                    .navigationDestination(isPresented: $isShowCurrencyRates) {
                        CurrencyRates()
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
            .navigationTitle("Настройки")
        }
        .onAppear(perform: getUser)
    }
    
    func getUser() {
        if users.isEmpty {
            Task {
                do {
                    let user = try await UserAPI().GetUser()
                    modelContext.insert(user)
                } catch {
                    debugLog(error)
                }
            }
        }
    }
}

#Preview {
    Profile()
        .environment(ModelData())
}
