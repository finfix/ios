//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

enum ChartDisplayType: CaseIterable {
    case linear, ring
    
    var name: String {
        switch self {
        case .linear: "Линейный"
        case .ring: "Кольцевой"
        }
    }
}

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
    case chartDrillDown(filters: TransactionFilters, chartType: ChartType)
}

struct ChartView: View {
    @Environment(AlertManager.self) private var alert
    @Binding var chartViewGroupBy: ChartViewGroupBy
    @State private var vm: ChartViewModel
    @State private var chartDisplayType: ChartDisplayType = .linear
    @State private var showFullScreenChart = false
    @Environment(PathSharedState.self) var path
    @Environment(\.calendar) var calendar
    @Binding var filters: TransactionFilters
    var currency: Currency
    
    init(
        chartType: ChartType = .earningsAndExpenses,
        chartViewGroupBy: Binding<ChartViewGroupBy>,
        filters: Binding<TransactionFilters>,
        currency: Currency,
        aggregateIntoParents: Bool = true
    ) {
        self.formatter = CurrencyFormatter(currency: currency, withUnits: false)
        self._chartViewGroupBy = chartViewGroupBy
        vm = ChartViewModel(chartType: chartType, aggregateIntoParents: aggregateIntoParents)
        self.currency = currency
        self._filters = filters
    }
    
    var formatter: CurrencyFormatter

    let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.3 // Треть экрана

    // Баланс всегда рисуется столбцами (см. Graph.swift), а не линией — подписываем
    // кнопку переключения вида соответственно, а не просто "Линейный".
    private var displayTypeIcon: String {
        if vm.chartType == .balance && chartDisplayType == .linear {
            return "chart.bar.fill"
        }
        return chartDisplayType == .linear ? "chart.xyaxis.line" : "chart.pie.fill"
    }

    private var displayTypeLabel: String {
        if vm.chartType == .balance && chartDisplayType == .linear {
            return "Столбчатый"
        }
        return chartDisplayType.name
    }
    
    var body: some View {
        normalContent
            .fullScreenCover(isPresented: $showFullScreenChart) {
                ChartFullScreenView(
                    vm: vm,
                    chartDisplayType: chartDisplayType,
                    chartViewGroupBy: chartViewGroupBy,
                    currency: currency,
                    formatter: formatter,
                    filters: $filters,
                    isPresented: $showFullScreenChart
                )
                // fullScreenCover не всегда наследует @Environment(PathSharedState.self) от
                // NavigationStack-предка — пробрасываем явно, иначе список серий крашится
                // при попытке перейти к транзакциям.
                .environment(path)
            }
    }

    private var normalContent: some View {
        VStack {
            Picker(vm.chartType.name, selection: $vm.chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.name)
                        .tag(type)
                }
            }
            HStack {
                if vm.chartType != .earningsAndExpenses {
                    Button {
                        chartDisplayType = chartDisplayType == .linear ? .ring : .linear
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: displayTypeIcon)
                            Text(displayTypeLabel)
                        }
                    }
                }
                Spacer()
                Button {
                    showFullScreenChart = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal)
            .padding(.bottom, 2)
            Menu {
                Picker("", selection: $vm.period) {
                    ForEach(ChartPeriod.allCases, id: \.self) { p in
                        Text(p.name).tag(p)
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    Text(vm.period.name)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.bottom, 2)
            }
            Group {
                if !vm.data.isEmpty {
                    if chartDisplayType == .ring && vm.chartType != .earningsAndExpenses {
                        RingGraph(
                            data: vm.data,
                            period: vm.period,
                            lastSelectedDate: $vm.lastSelectedDate,
                            currency: currency
                        )
                    } else {
                        Graph(
                            chartType: vm.chartType,
                            period: vm.period,
                            data: vm.data,
                            lastSelectedDate: $vm.lastSelectedDate,
                            currency: currency
                        )
                        .id(vm.period)
                    }
                } else {
                    Text("Нет данных для отображения")
                }
            }
            .frame(height: chartHeight)
            VStack {
                HStack {
                    if vm.chartType == .earnings || vm.chartType == .expenses {
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
                    } else if vm.chartType == .balance {
                        Text("Счёт")
                            .font(.caption)
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
                if !vm.data.isEmpty {
                    let totalLabel = vm.chartType == .balance ? "Итого" : "Всего"
                    let aggregationTotal = vm.aggregationInformation.values.reduce(0, +)
                    let selectedDateTotal = vm.totalBySelectedDate
                    let isPercent = vm.aggregationMethod == .percent
                    Divider()
                    LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible()), GridItem(.flexible())]) {
                        Text(totalLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Spacer()
                            if isPercent {
                                Text(aggregationTotal, format: .percent.precision(.fractionLength(0)))
                            } else {
                                Text(formatter.string(number: aggregationTotal))
                            }
                        }
                        .foregroundStyle(.secondary)
                        HStack {
                            Spacer()
                            Text(formatter.string(number: selectedDateTotal))
                        }
                    }
                    .bold()
                    .padding(.top, 4)
                    .font(.callout)
                }
            }
            .padding(.horizontal, 15)
        }
        .task {
            do {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            } catch {
                alert.error(error)
            }
        }
        .onChange(of: vm.chartType) { _, newType in
            if newType == .earningsAndExpenses || newType == .balance {
                chartDisplayType = .linear
            }
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
        .onChange(of: vm.period) { _, newPeriod in
            vm.lastSelectedDate = Date.now.startOfPeriod(newPeriod)
            vm.data = []
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
        filters: .constant(TransactionFilters(accountGroups: [])),
        currency:
            Currency(
                symbol: "₽"
            )
    )
        .environment(AlertManager(handle: {_ in }))
}
