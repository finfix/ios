//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

enum ChartViewGroupBy: CaseIterable {
    case byTag, byAccount
    
    var name: String {
        switch self {
        case .byAccount: "Счет"
        case .byTag: "Подкатегория"
        }
    }
}

enum ChartViewRoute: Hashable {
    case transactionView(filters: TransactionFilters, chartType: ChartType)
}

struct ChartView: View {
    @Environment(AlertManager.self) private var alert
    @Binding var chartViewGroupBy: ChartViewGroupBy
    @State private var vm: ChartViewModel
    @Environment(PathSharedState.self) var path
    @Environment(\.calendar) var calendar
    @Binding var filters: TransactionFilters
    var currency: Currency
    
    init(
        chartType: ChartType = .earningsAndExpenses,
        chartViewGroupBy: Binding<ChartViewGroupBy>,
        filters: Binding<TransactionFilters>,
        currency: Currency
    ) {
        self.formatter = CurrencyFormatter(currency: currency, withUnits: false)
        self._chartViewGroupBy = chartViewGroupBy
        vm = ChartViewModel(chartType: chartType)
        self.currency = currency
        self._filters = filters
    }
    
    var formatter: CurrencyFormatter
    
    let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.3 // Треть экрана
    
    var body: some View {
        VStack {
            Picker(vm.chartType.name, selection: $vm.chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.name)
                        .tag(type)
                }
            }
            Group {
                if !vm.data.isEmpty {
                    Graph(
                        chartType: vm.chartType,
                        data: vm.data,
                        lastSelectedDate: $vm.lastSelectedDate,
                        currency: currency
                    )
                } else {
                    Text("Нет данных для отображения")
                }
            }
            .frame(height: chartHeight)
            VStack {
                HStack {
                    if vm.chartType != .earningsAndExpenses {
                        Menu {
                            Picker("", selection: $chartViewGroupBy) {
                                ForEach(ChartViewGroupBy.allCases, id: \.self) { groupBy in
                                    Text(groupBy.name)
                                        .tag(groupBy)
                                }
                            }
                        } label: {
                            HStack {
                                Text(chartViewGroupBy.name)
                                Image(systemName: "chevron.up.chevron.down")
                                Spacer()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .id(chartViewGroupBy)
                        .frame(minWidth: 150)
                    } else {
                        Text("Тип")
                            .font(.caption)
                    }
                    
                    Spacer()
                    Menu {
                        Picker("", selection: $vm.aggregationMethod) {
                            ForEach(ChartViewModel.AggregationMethod.allCases.filter{
                                vm.chartType == .earningsAndExpenses
                                ? ($0 != .percent && $0 != .budget)
                                : true
                            }, id: \.self) { method in
                                Text(method.name)
                                    .tag(method)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(vm.aggregationMethod.name)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .id(vm.aggregationMethod)
                    
                    HStack {
                        Spacer()
                        Text("Сумма")
                    }
                }
                .bold()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(Array(vm.data.enumerated()), id: \.element) { (i, series) in
                            ChartListItemView(
                                chartViewGroupBy: chartViewGroupBy,
                                vm: $vm,
                                series: series,
                                currency: currency,
                                filters: $filters
                            )
                        }
                    }
                }
                .font(.callout)
                if vm.chartType != .earningsAndExpenses {
                    HStack {
                        Text("Всего:")
                        Spacer()
                        Text(formatter.string(number: vm.totalBySelectedDate))
                    }
                    .padding(.top)
                    .font(.title2)
                }
            }
            .padding(.horizontal, 15)
        }
        .task {
            do {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            } catch {
                alert(error)
            }
        }
        .onChange(of: vm.chartType) { _, _ in
            Task {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            }
        }
        .onChange(of: filters) { _, _ in
            Task {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            }
        }
        .onChange(of: chartViewGroupBy) { _, _ in
            Task {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            }
        }
    }
}

#Preview {
    ChartView(
        chartType: .expenses,
        chartViewGroupBy: .constant(ChartViewGroupBy.byAccount),
        filters: .constant(TransactionFilters()),
        currency:
            Currency(
                symbol: "₽"
            )
    )
        .environment(AlertManager(handle: {_ in }))
}
