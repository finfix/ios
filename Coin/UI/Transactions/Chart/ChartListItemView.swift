//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

struct ChartListItemView: View {
    
    var chartViewGroupBy: ChartViewGroupBy
    @Binding var vm: ChartViewModel
    @Environment(PathSharedState.self) var path
    @Binding var filters: TransactionFilters
    
    var series: Series
    
    var formatter: CurrencyFormatter
    
    init(
        chartViewGroupBy: ChartViewGroupBy,
        vm: Binding<ChartViewModel>,
        series: Series,
        currency: Currency,
        filters: Binding<TransactionFilters>
    ) {
        self.formatter = CurrencyFormatter(currency: currency, withUnits: false)
        self.chartViewGroupBy = chartViewGroupBy
        self._vm = vm
        self.series = series
        self._filters = filters
    }
        
    var body: some View {
        if chartViewGroupBy == .byAccount, let account = series.account {
            Button {
                if account.isParent && !account.childrenAccounts.isEmpty {
                    // Открываем drill-down график по дочерним счетам родителя
                    var drillDownFilters = filters
                    drillDownFilters.accounts = account.childrenAccounts
                    path.path.append(ChartViewRoute.chartDrillDown(filters: drillDownFilters, chartType: vm.chartType))
                } else {
                    filters.accounts.append(account)
                    path.path.append(ChartViewRoute.transactionView(filters: filters, chartType: vm.chartType))
                }
            } label: {
                HStack {
                    HStack {
                        Text(account.name)
                        Text(account.currency.symbol)
                    }
                    .foregroundStyle(series.color)
                    .frame(height: 30)
                    Spacer()
                }
            }
        } else if chartViewGroupBy == .byTag, let tag = series.tag {
            Button {
                filters.tags.append(tag)
                path.path.append(ChartViewRoute.transactionView(filters: filters, chartType: vm.chartType))
            } label: {
                HStack {
                    Text(tag.name)
                        .foregroundStyle(series.color)
                        .frame(height: 30)
                    Spacer()
                }
            }
        } else if let type = series.type {
            Button {
                switch type {
                case .expense:
                    path.path.append(ChartViewRoute.transactionView(filters: filters, chartType: .expenses))
                case .income:
                    path.path.append(ChartViewRoute.transactionView(filters: filters, chartType: .earnings))
                }
            } label: {
                HStack {
                    Text(type.name)
                        .foregroundStyle(series.color)
                        .frame(height: 30)
                    Spacer()
                }
            }
        }
        HStack {
            Spacer()
            if vm.aggregationMethod == .percent {
                Text(vm.aggregationInformation[series.id] ?? 0, format: .percent.precision(.fractionLength(0)))
            } else {
                Text(formatter.string(number: vm.aggregationInformation[series.id] ?? 0))
            }
        }
        .foregroundStyle(.secondary)
        HStack {
            Spacer()
            Text(formatter.string(number: series.data[vm.lastSelectedDate] ?? 0))
        }
    }
}

//#Preview {
//    ChartView(
//        chartType: .expenses, 
//        selectedAccountGroup: 
//            AccountGroup(
//                id: 5,
//                currency:
//                    Currency(
//                        symbol: "₽"
//                    )
//            ),
//        filters: TransactionFilters()
//    )
//        .environment(AlertManager(handle: {_ in }))
//}
