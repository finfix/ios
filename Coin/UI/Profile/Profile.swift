//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

enum ProfileViews {
    case hidedAccounts, currencyRates, settings
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
                }
                #else
                if !isProdAPI {
                    Section {
                        Text("Тестовое окружение")
                            .foregroundColor(.yellow)
                    }
                }
                #endif
                Section {
                    NavigationLink("Cкрытые счета", value: ProfileViews.hidedAccounts)
                    NavigationLink("Курсы валют", value: ProfileViews.currencyRates)
                }
                Section {
                    Button {
                        Task {
                            shouldDisableUI = true
                            shouldShowProgress = true
                            
                            do {
                                try await vm.sync()
                            } catch {
                                alert(error)
                            }
                            
                            shouldShowProgress = false
                            shouldDisableUI = false
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
            .navigationDestination(for: ProfileViews.self) { view in
                switch view {
                case .hidedAccounts: HidedAccountsList(selectedAccountGroup: $selectedAccountGroup, path: $path)
                case .currencyRates: CurrencyRates()
                case .settings: Settings()
                }
            }
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
