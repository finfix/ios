//
//  AccountCirclesTab.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI

struct AccountCirclesTab: View {
    
    @State var path = PathSharedState()
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    
    var body: some View {
        NavigationStack(path: $path.path) {
            AccountCirclesView()
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
        }
        .environment(path)
    }
}

#Preview {
    AccountCirclesTab()
}
