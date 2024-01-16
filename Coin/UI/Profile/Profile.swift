//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

enum ProfileViews {
    case hidedAccounts, currencyRates, settings
}

struct Profile: View {
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @AppStorage("accountGroupIndex") var accountGroupIndex: Int = 0
    @State var shouldShowSuccess = false
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    
    @Environment(\.modelContext) var modelContext
    @State var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                
                Section {
                    NavigationLink("Cкрытые счета", value: ProfileViews.hidedAccounts)
                    NavigationLink("Курсы валют", value: ProfileViews.currencyRates)
                }
                Section {
                    Button("Синхронизировать") {
                        Task {
                            shouldDisableUI = true
                            shouldShowProgress = true
                            await LoadModelActor(modelContainer: modelContext.container).sync()
                            shouldShowProgress = false
                            shouldDisableUI = false
                            withAnimation(.spring().delay(0.25)) {
                                self.shouldShowSuccess.toggle()
                            }
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
                case .hidedAccounts: HidedAccountsList(path: $path)
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
    Profile()
        .modelContainer(container)
}
