//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct TransactionsTab: View {
    
    @State var path = NavigationPath()
    
    @Binding var selectedAccountGroup: AccountGroup
    
    var body: some View {
        NavigationStack(path: $path) {
            TransactionsView(path: $path, selectedAccountGroup: $selectedAccountGroup, chartType: .earningsAndExpenses)
                .navigationDestination(for: TransactionsListRoute.self) { screen in
                    switch screen {
                    case .editTransaction(let transaction):
                        EditTransaction(transaction, path: $path)
                    }
                }
                .navigationDestination(for: EditTransactionRoute.self) { screen in
                    switch screen {
                    case .tagsList:
                        TagsList(accountGroup: selectedAccountGroup, path: $path)
                    }
                }
                .navigationDestination(for: TagsListRoute.self) { screen in
                    switch screen {
                    case .createTag:
                        EditTag(selectedAccountGroup: selectedAccountGroup, path: $path)
                    case .editTag(let tag):
                        EditTag(tag, path: $path)
                    }
                }
                .navigationDestination(for: ChartViewRoute.self) { screen in
                    switch screen {
                    case .transactionList(account: let account):
                        TransactionsView(path: $path, selectedAccountGroup: $selectedAccountGroup, account: account)
                    case .transactionList1(chartType: let chartType):
                        TransactionsView(path: $path, selectedAccountGroup: $selectedAccountGroup, chartType: chartType)
                    }
                }
        }
    }
}

#Preview {
    TransactionsTab(selectedAccountGroup: .constant(AccountGroup(id: 4)))
        .environment(AlertManager(handle: {_ in }))
}
