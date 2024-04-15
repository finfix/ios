//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesView")

struct AccountCirclesView: View {
    
    @Environment (AlertManager.self) private var alert
    @Binding var selectedAccountGroup: AccountGroup
    @State var path = NavigationPath()
    @State var vm = AccountCirclesViewModel()
    
    let horizontalSpacing: CGFloat = 10
    
    var groupedAccounts: [Account] {
        Account.groupAccounts(vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup
        })
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 5) {
                VStack(spacing: 0) {
                    QuickStatisticView(selectedAccountGroup: selectedAccountGroup)
                    AccountGroupSelector(selectedAccountGroup: $selectedAccountGroup)
                }
                VStack {
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder > 0) }) { account in
                                AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                            }
                            PlusNewAccount(accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .regular }) { account in
                                AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                            }
                            PlusNewAccount(accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.adaptive(minimum: 100))], alignment: .top, spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .expense || ($0.type == .balancing && $0.showingRemainder < 0)}) { account in
                                AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                            }
                            PlusNewAccount(accountType: .expense)
                        }
                    }
                }
                .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
                .scrollIndicators(.hidden)
                .navigationDestination(for: Account.self) { EditAccount($0, selectedAccountGroup: selectedAccountGroup) }
                .navigationDestination(for: AccountType.self) { EditAccount(accountType: $0, accountGroup: selectedAccountGroup) }
            }
            Spacer()
            .task {
                do {
                    try vm.load()
                } catch {
                    alert(error)
                }
            }
        }
        
    }
}

#Preview {
    AccountCirclesView(selectedAccountGroup: .constant(AccountGroup()))
}
