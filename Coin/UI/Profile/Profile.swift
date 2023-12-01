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
    @AppStorage("accountGroupIndex") var accountGroupIndex: Int = 0
    
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
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
                    Button("Синхронизировать") {
                        Task {
                            await LoadModelActor(modelContainer: modelContext.container).sync()
                        }
                    }
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
                        Task {
                            await LoadModelActor(modelContainer: modelContext.container).deleteAll()
                        }
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
    }
}

#Preview {
    Profile()
}
