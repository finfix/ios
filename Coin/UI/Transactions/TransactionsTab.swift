//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct TransactionsTab: View {
        
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @Environment(PathSharedState.self) var path
    
    var body: some View {
        @Bindable var path = path
        NavigationStack(path: $path.path) {
            TransactionsView(chartType: .earningsAndExpenses)
                .navigationDestination(for: TransactionsListRoute.self) { screen in
                    switch screen {
                    case .editTransaction(let transaction):
                        EditTransaction(transaction)
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
    }
}

#Preview {
    TransactionsTab()
        .environment(AlertManager(handle: {_ in }))
}
