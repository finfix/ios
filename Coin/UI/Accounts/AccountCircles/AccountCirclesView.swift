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
                            PlusNewAccount(path: $path, accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .regular }) { account in
                                AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                            }
                            PlusNewAccount(path: $path, accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.adaptive(minimum: 100))], alignment: .top, spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .expense || ($0.type == .balancing && $0.showingRemainder < 0)}) { account in
                                AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                            }
                            PlusNewAccount(path: $path, accountType: .expense)
                        }
                    }
                }
                .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
                .scrollIndicators(.hidden)
            }
            Spacer()
            .task {
                do {
                    try await vm.load()
                } catch {
                    alert(error)
                }
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account): TransactionsList(path: $path, selectedAccountGroup: $selectedAccountGroup, account: account)
                case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup, isHiddenView: false)
                }
            }
            .navigationDestination(for: PlusNewAccountRoute.self) { screen in
                switch screen {
                case .createAccount(let accountType): EditAccount(accountType: accountType, accountGroup: selectedAccountGroup)
                }
            }
            .navigationDestination(for: TransactionsListRoute.self) { screen in
                switch screen {
                case .editTransaction(let transaction): EditTransaction(transaction)
                }
            }
//            .onChange(of: selectedAccountGroup) { _, newValue in
//                vm.load() // Передавать ид группы
//            }
        }
    }
}

#Preview {
    AccountCirclesView(selectedAccountGroup: .constant(AccountGroup()))
        .environment(AlertManager(handle: {_ in }))
}
