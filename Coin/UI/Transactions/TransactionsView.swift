//
//  TransactionsView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI

struct TransactionFilters: Equatable {
    var searchText = ""
    var dateFrom: Date?
    var dateTo: Date?
    var transactionType: TransactionType?
    var currency: Currency?
    var account: Account? = nil
}

struct TransactionsView: View {
    
    @Binding var path: NavigationPath
    @State var isFilterOpen = false
    @State var filters: TransactionFilters
    @Binding var selectedAccountGroup: AccountGroup
    var chartType: ChartType
    
    init(
        path: Binding<NavigationPath>,
        selectedAccountGroup: Binding<AccountGroup>,
        account: Account? = nil,
        chartType: ChartType = .earningsAndExpenses
    ) {
        self._path = path
        self._selectedAccountGroup = selectedAccountGroup
        self.filters = TransactionFilters(account: account)
        self.chartType = chartType
    }
    
    var body: some View {
        TransactionsList(
            path: $path,
            selectedAccountGroup: $selectedAccountGroup,
            filters: filters,
            chartType: chartType
        )
        .searchable(text: $filters.searchText)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // Фильтры
                Button { isFilterOpen.toggle() } label: { Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle") }
            }
        }
        .sheet(isPresented: $isFilterOpen) {
            TransactionFilterView(
                accountGroup: $selectedAccountGroup, 
                filters: $filters
            )
        }

    }
}

#Preview {
    TransactionsView(
        path: .constant(NavigationPath()),
        selectedAccountGroup: .constant(
            AccountGroup(
                id: 4,
                currency:
                    Currency(
                        symbol: "$"
                    )
            )
        )
    )
    .environment(AlertManager(handle: {_ in }))
}
