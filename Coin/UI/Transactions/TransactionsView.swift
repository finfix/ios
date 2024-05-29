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
    
    @Environment(PathSharedState.self) var path
    @State var isFilterOpen = false
    @State var filters: TransactionFilters
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    var chartType: ChartType
    
    init(
        account: Account? = nil,
        chartType: ChartType = .earningsAndExpenses
    ) {
        self.filters = TransactionFilters(account: account)
        self.chartType = chartType
    }
    
    var body: some View {
        TransactionsList(
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
                filters: $filters
            )
        }

    }
}

#Preview {
    TransactionsView()
    .environment(AlertManager(handle: {_ in }))
}
