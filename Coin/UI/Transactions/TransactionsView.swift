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
    var transactionTypes: [TransactionType] = []
    var currencies: [Currency] = []
    var accounts: [Account] = []
    // Счета (и их дочерние счета), транзакции по которым нужно скрыть из выборки.
    var excludedAccounts: [Account] = []
    var tags: [Tag] = []
    var accountGroups: [AccountGroup]
}

struct TransactionsView: View {
    
    @Environment(PathSharedState.self) var path
    @Environment(AccountGroupSharedState.self) private var selectedAccountGroup
    @State var filters: TransactionFilters
    @State var searchText: String = ""
    @State var chartType: ChartType
    @State var chartGroupBy: ChartViewGroupBy = .byAccount
    @State var vm: TransactionsViewModel = TransactionsViewModel()
    @State private var showFilters: Bool = false
    @State private var areFiltersLocked: Bool = false
    @State private var isChartFullScreen: Bool = false
    let aggregateIntoParents: Bool

    var hasActiveFilters: Bool {
        filters != TransactionFilters(accountGroups: [selectedAccountGroup.selectedAccountGroup])
    }

    var currency: Currency {
        if filters.accountGroups.count == 1 {
            return filters.accountGroups[0].currency
        } else {
            return vm.user.defaultCurrency
        }
    }
    
    init(
        filters: TransactionFilters,
        chartType: ChartType = .earningsAndExpenses,
        aggregateIntoParents: Bool = true
    ) {
        self.filters = filters
        self.chartType = chartType
        self.aggregateIntoParents = aggregateIntoParents
    }

    var body: some View {
        VStack {
            // Если строка поиска пустая -> Показываем список транзакций
            if !showFilters {
                // ChartView всегда остаётся на одном и том же месте в дереве (просто внутри
                // ScrollView) — если рисовать её в двух разных ветках if/else (как раньше),
                // SwiftUI теряет идентичность вью при переключении в полноэкранный режим и
                // обратно, из-за чего вместе с ChartViewModel сбрасываются и фильтры/тип
                // графика. В полноэкранном режиме просто растягиваем её на всю высоту и
                // прячем строку фильтров/список транзакций, а скролл отключаем.
                GeometryReader { geo in
                    ScrollView {
                        if !isChartFullScreen {
                            TransactionFiltersRowView(filters: $filters)
                        }
                        ChartView(
                            chartType: chartType,
                            chartViewGroupBy: $chartGroupBy,
                            filters: $filters,
                            currency: currency,
                            aggregateIntoParents: aggregateIntoParents,
                            isFullScreen: $isChartFullScreen
                        )
                        // height (не minHeight!) — иначе при длинном списке серий контент
                        // ChartFullScreenView просто продавливает контейнер выше экрана, и
                        // "Всего" внизу становится недоступной (скролл-то отключён).
                        .frame(height: isChartFullScreen ? geo.size.height : nil)
                        if !isChartFullScreen {
                            TransactionsList(filters: filters)
                        }
                    }
                    .scrollDisabled(isChartFullScreen)
                }
            } else { // Если в строку поиска уже что-то написали
                SearchView(
                    searchText: $searchText,
                    filters: $filters,
                    chartType: $chartType,
                    showFilters: $showFilters,
                    areFiltersLocked: $areFiltersLocked
                )
            }
        }
        .task {
            do {
                try await vm.load()
            } catch {
                
            }
        }
        .onChange(of: selectedAccountGroup.selectedAccountGroup) { oldValue, newValue in
            if !areFiltersLocked {
                filters.accountGroups = [newValue]
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showFilters.toggle()
                } label: {
                    Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

#Preview {
    TransactionsView(filters: TransactionFilters(
        accountGroups: []
    ))
    .environment(AlertManager(handle: {_ in }))
}

// TODO: Сделать PreviewCoinApp с нужными .environment
