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
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
        
    @Environment(\.modelContext) var modelContext
    @State var path = NavigationPath()

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
                            shouldDisableUI = true
                            shouldShowProgress = true
                            await LoadModelActor(modelContainer: modelContext.container).sync()
                            shouldShowProgress = false
                            shouldDisableUI = false
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
                            shouldDisableUI = true
                            defer { shouldDisableUI = false }
                            do {
                                try await LoadModelActor(modelContainer: modelContext.container).deleteAll()
                            } catch {
                                showErrorAlert("\(error)")
                            }
                        }                       
                        accountGroupIndex = 0
                        isLogin = false
                        accessToken = nil
                        refreshToken = nil
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(shouldDisableUI)
            .overlay {
                if shouldShowProgress {
                    ProgressView()
                }
            }
            .navigationDestination(for: ProfileViews.self) { view in
                switch view {
                case .hidedAccounts: HidedAccountsList(path: $path)
                case .currencyRates: CurrencyRates()
                }
            }
            .navigationDestination(for: Account.self) { EditAccount($0) }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    Profile()
        .modelContainer(previewContainer)
}
