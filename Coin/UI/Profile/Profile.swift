//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

enum ProfileViews: Hashable {
    case hidedAccounts
    case currencyConverter
    case settings
}

struct Profile: View {
    
    @Environment (AlertManager.self) private var alert
    @State var vm = ProfileViewModel()
    
    @Binding var selectedAccountGroup: AccountGroup
    
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @AppStorage("apiBasePath") private var apiBasePath = defaultApiBasePath
    var isProdAPI: Bool {
        apiBasePath == defaultApiBasePath
    }
    @State var shouldShowSuccess = false
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    
    @State var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                #if DEBUG
                Section {
                    Text(isProdAPI ? "Продакшн окружение" : "Тестовое окружение")
                        .foregroundColor(isProdAPI ? .red : .yellow)
                    if !isProdAPI {
                        Text(apiBasePath)
                            .foregroundStyle(.secondary)
                    }
                }
                #else
                if !isProdAPI {
                    Section {
                        Text("Тестовое окружение")
                            .foregroundColor(.yellow)
                        Text(apiBasePath)
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
                Section {
                    NavigationLink("Cкрытые счета", value: ProfileViews.hidedAccounts)
                    NavigationLink("Конвертер валют", value: ProfileViews.currencyConverter)
                }
                .buttonStyle(.plain)
                Section {
                    Button {
                        Task {
                            shouldDisableUI = true
                            shouldShowProgress = true
                            defer {
                                shouldShowProgress = false
                                shouldDisableUI = false
                            }
                            
                            do {
                                try await vm.sync()
                            } catch {
                                alert(error)
                                return
                            }
                            
                            withAnimation(.spring().delay(0.25)) {
                                self.shouldShowSuccess.toggle()
                            }
                        }
                    } label: {
                        if !shouldShowProgress {
                            Text("Синхронизировать")
                        } else {
                            ProgressView()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Section {
                    Button("Выйти", role: .destructive) {
                        Task {
                            do {
                                try await vm.deleteAll()
                            } catch {
                                alert(error)
                            }
                        }
                        isLogin = false
                        accessToken = nil
                        refreshToken = nil
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(shouldDisableUI)
            .overlay {
                if shouldShowSuccess {
                    CheckmarkPopover()
                        .onAppear {
                            Task {
                                try await Task.sleep(for: .seconds(1))
                                withAnimation(.spring()) {
                                    self.shouldShowSuccess = false
                                }
                            }
                        }
                }
            }
            .navigationDestination(for: ProfileViews.self) { screen in
                switch screen {
                case .hidedAccounts: HidedAccountsList(selectedAccountGroup: $selectedAccountGroup, path: $path)
                case .currencyConverter: CurrencyConverter()
                case .settings: Settings(path: $path)
                }
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account): TransactionsView(path: $path, selectedAccountGroup: $selectedAccountGroup, account: account)
                case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup, isHiddenView: false)
                }
            }
            .navigationDestination(for: TransactionsListRoute.self) { screen in
                switch screen {
                case .editTransaction(let transaction): EditTransaction(transaction, path: $path)
                }
            }
            .navigationDestination(for: SettingsRoute.self, destination: { screen in
                switch screen {
                case .tasksList: TasksList(path: $path)
                }
            })
            .navigationDestination(for: TasksListRoute.self, destination: { screen in
                switch screen {
                case .taskDetails(let task): TaskDetails(task: task)
                }
            })
            .toolbar {
                ToolbarItem {
                    NavigationLink(value: ProfileViews.settings) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

#Preview {
    Profile(selectedAccountGroup: .constant(AccountGroup()))
}
