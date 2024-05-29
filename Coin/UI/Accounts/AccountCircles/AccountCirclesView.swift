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
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @State var path = PathSharedState()
    @State var vm = AccountCirclesViewModel()
    
    let horizontalSpacing: CGFloat = 10
    
    var groupedAccounts: [Account] {
        Account.groupAccounts(vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup.selectedAccountGroup
        })
    }
    
    var body: some View {
        NavigationStack() {
            VStack(spacing: 5) {
                VStack(spacing: 0) {
                    QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                    AccountGroupSelector()
                }
                VStack {
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder > 0) }) { account in
                                AccountCircleItem(account)
                            }
                            PlusNewAccount(accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .regular }) { account in
                                AccountCircleItem(account)
                            }
                            PlusNewAccount(accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.adaptive(minimum: 100))], alignment: .top, spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .expense || ($0.type == .balancing && $0.showingRemainder < 0)}) { account in
                                AccountCircleItem(account)
                            }
                            PlusNewAccount(accountType: .expense)
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
                case .accountTransactions(let account): TransactionsView(account: account)
                case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup, isHiddenView: false)
                }
            }
            .navigationDestination(for: PlusNewAccountRoute.self) { screen in
                switch screen {
                case .createAccount(let accountType): EditAccount(accountType: accountType, accountGroup: selectedAccountGroup.selectedAccountGroup)
                }
            }
            .navigationDestination(for: TransactionsListRoute.self) { screen in
                switch screen {
                case .editTransaction(let transaction): EditTransaction(transaction)
                }
            }
            .navigationDestination(for: EditTransactionRoute.self) { screen in
                switch screen {
                case .tagsList:
                    TagsList(accountGroup: selectedAccountGroup.selectedAccountGroup)
                }
            }
            .navigationDestination(for: TagsListRoute.self) { screen in
                switch screen {
                case .createTag:
                    EditTag(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                case .editTag(let tag):
                    EditTag(tag)
                }
            }
            .navigationDestination(for: ChartViewRoute.self) { screen in
                switch screen {
                case .transactionList(account: let account):
                    TransactionsView(account: account)
                case .transactionList1(chartType: let chartType):
                    TransactionsView(chartType: chartType)
                }
            }
            .environment(path)
        }
    }
}

#Preview {
    AccountCirclesView()
        .environment(AlertManager(handle: {_ in }))
}
