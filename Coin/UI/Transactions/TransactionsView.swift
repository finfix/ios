//
//  TransactionsView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI

struct TransactionsView: View {
    
    @Binding var path: NavigationPath
    @State var isFilterOpen = false
    @State private var searchText = ""
    @State var dateFrom: Date?
    @State var dateTo: Date?
    @State var transactionType: TransactionType?
    @State var currency: Currency?
    @Binding var selectedAccountGroup: AccountGroup
    var account: Account? = nil
    var chartType: ChartType = .earningsAndExpenses
    
    
    var body: some View {
        TransactionsList(
            path: $path,
            selectedAccountGroup: $selectedAccountGroup,
            account: account, 
            searchText: searchText,
            dateFrom: dateFrom,
            dateTo: dateTo,
            transactionType: transactionType,
            currency: currency,
            chartType: chartType
        )
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Фильтры
                    Button { isFilterOpen.toggle() } label: { Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle") }
                }
            }
            .sheet(isPresented: $isFilterOpen) {
                TransactionFilterView(
                    dateFrom: $dateFrom,
                    dateTo: $dateTo,
                    transactionType: $transactionType,
                    accountGroup: $selectedAccountGroup,
                    currency: $currency
                )
            }

    }
}

#Preview {
    TransactionsView(path: .constant(NavigationPath()), selectedAccountGroup: .constant(AccountGroup(id: 4, currency: Currency(symbol: "$"))))
        .environment(AlertManager(handle: {_ in }))
}
