//
//  TransactionsView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI

struct TransactionFilters: Equatable, Hashable {
    var searchText = ""
    var dateFrom: Date?
    var dateTo: Date?
    var transactionType: TransactionType?
    var currency: Currency?
    var accounts: [Account] = []
    var tags: [Tag] = []
    var accountGroups: [AccountGroup] = []
}

struct TransactionsView: View {
    
    @Environment(PathSharedState.self) var path
    @State var isFilterOpen = false
    @State var filters: TransactionFilters
    @State var searchText: String = ""
    @State var chartType: ChartType
    @State var chartGroupBy: ChartViewGroupBy = .byAccount
    @State var vm: TransactionsViewModel = TransactionsViewModel()
    
    var currency: Currency {
        if filters.accountGroups.count == 1 {
            return filters.accountGroups[0].currency
        } else {
            return vm.user.defaultCurrency
        }
    }
    
    init(
        filters: TransactionFilters,
        chartType: ChartType = .earningsAndExpenses
    ) {
        self.filters = filters
        self.chartType = chartType
    }

    var body: some View {
        ZStack {
            // Если строка поиска пустая -> Показываем список транзакций
            if searchText == "" {
                ScrollView {
                    ChartView(
                        chartType: chartType,
                        chartViewGroupBy: $chartGroupBy,
                        filters: filters,
                        currency: currency
                    )
                    TransactionsList(filters: filters)
                }
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
            } else { // Если в строку поиска уже что-то написали
                SearchView(searchText: $searchText, filters: $filters, chartType: $chartType)
            }
        }
        .task {
            do {
                try await vm.load()
            } catch {
                
            }
        }
        .searchable(text: $searchText)
    }
}

#Preview {
    TransactionsView(filters: TransactionFilters())
    .environment(AlertManager(handle: {_ in }))
}

// TODO: Сделать PreviewCoinApp с нужными .environment
