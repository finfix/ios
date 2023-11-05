//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

enum ProfileViews {
    case hidedAccounts, currencyRates
}

struct Profile: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @AppStorage("basePath") private var basePath: String = defaultBasePath
    
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
                    Button("Синхронизировать") {}
                    NavigationLink("Cкрытые счета", value: ProfileViews.hidedAccounts)
                    NavigationLink("Курсы валют", value: ProfileViews.currencyRates)
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
                    Button("Выйти", role: .destructive) {
                        isLogin = false
                        accessToken = nil
                        refreshToken = nil
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .navigationDestination(for: ProfileViews.self) { view in
                switch view {
                case .currencyRates: CurrencyRates()
                case .hidedAccounts: HidedAccountsList()
                }
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
}
