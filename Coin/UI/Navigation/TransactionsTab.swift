//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct TransactionsTab: View {
        
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @State var path = PathSharedState()
    
    var body: some View {
        NavigationStack(path: $path.path) {
            TransactionsView(filters: TransactionFilters(accountGroups: [selectedAccountGroup.selectedAccountGroup]), chartType: .earningsAndExpenses)
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
                    case .transactionView(let filters, let chartType):
                        TransactionsView(filters: filters, chartType: chartType)
                    case .chartDrillDown(let filters, let chartType):
                        TransactionsView(filters: filters, chartType: chartType, aggregateIntoParents: false)
                    }
                }
        }
        .environment(path)
    }
}

#Preview {
    TransactionsTab()
        .environment(AlertManager(handle: {_ in }))
}
