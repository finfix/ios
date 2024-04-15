//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

enum ProfileViews: Hashable {
    case hidedAccounts
    case currencyRates
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
                    }
                }
                #else
                if !isProdAPI {
                    Section {
                        Text("Тестовое окружение")
                            .foregroundColor(.yellow)
                        Text(apiBasePath)
                    }
                }
                #endif
                Section {
                    Button("Cкрытые счета") {
                        path.append(ProfileViews.hidedAccounts)
                    }
                    Button("Курсы валют") {
                        path.append(ProfileViews.currencyRates)
                    }
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
                                try vm.deleteAll()
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
                case .currencyRates: CurrencyRates()
                case .settings: Settings()
                }
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account): TransactionsList(path: $path, selectedAccountGroup: $selectedAccountGroup, account: account)
                case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup, isHiddenView: false)
                }
            }
            .navigationDestination(for: TransactionsListRoute.self) { screen in
                switch screen {
                case .editTransaction(let transaction): EditTransaction(transaction)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        path.append(ProfileViews.settings)
                    } label: {
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
