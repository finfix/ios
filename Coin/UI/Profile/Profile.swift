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
    case accountGroupsList
}

struct Profile: View {
    
    @Environment (AlertManager.self) private var alert
    @State var vm = ProfileViewModel()
    
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    @State var shouldShowSuccess = false
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    
    var body: some View {
        Form {
            Section {
                NavigationLink("Cкрытые счета", value: ProfileViews.hidedAccounts)
                NavigationLink("Конвертер валют", value: ProfileViews.currencyConverter)
                NavigationLink("Группы счетов", value: ProfileViews.accountGroupsList)
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

#Preview {
    Profile()
}
