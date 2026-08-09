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

// Баланс всегда рисуется столбцами (см. Graph.swift), а не линией — подписываем
// кнопку переключения вида соответственно, а не просто "Линейный". Общие для обычного
// и полноэкранного режима, поэтому вынесены наружу.
func chartDisplayTypeIcon(chartType: ChartType, displayType: ChartDisplayType) -> String {
    if (chartType == .balance || chartType == .balanceTotal) && displayType == .linear {
        return "chart.bar.fill"
    }
    return displayType == .linear ? "chart.xyaxis.line" : "chart.pie.fill"
}

func chartDisplayTypeLabel(chartType: ChartType, displayType: ChartDisplayType) -> String {
    if (chartType == .balance || chartType == .balanceTotal) && displayType == .linear {
        return "Столбчатый"
    }
    return displayType.name
}

/// Заголовок левой колонки списка серий — общий для обычного и полноэкранного режима.
func chartListHeaderLabel(chartType: ChartType, chartViewGroupBy: ChartViewGroupBy) -> String {
    switch chartType {
    case .earnings, .expenses: chartViewGroupBy.name
    case .balance: "Счёт"
    case .balanceTotal: "Итого"
    case .delta: "Дельта"
    case .earningsAndExpenses: "Тип"
    }
}

/// Сортировка серий по сумме (значению из `aggregationInformation`, той же, что
/// отображается в колонке "Сумма"), по убыванию. Нулевые серии всегда уходят в конец.
func seriesSortedByAmount(_ series: [Series], using vm: ChartViewModel) -> [Series] {
    series.sorted { a, b in
        let aValue = vm.aggregationInformation[a.id] ?? 0
        let bValue = vm.aggregationInformation[b.id] ?? 0
        if aValue == 0 { return false }
        if bValue == 0 { return true }
        return aValue > bValue
    }
}

struct ChartView: View {
    @Environment(AlertManager.self) private var alert
    @Binding var chartViewGroupBy: ChartViewGroupBy
    @State private var vm: ChartViewModel
    @State private var chartDisplayType: ChartDisplayType = .linear
    /// Сортировка серий по сумме включается тапом на заголовок колонки "Сумма".
    @State private var isSortedByAmount = false
    /// Управляется снаружи (из `TransactionsView`), т.к. в полноэкранном режиме нужно
    /// убрать список транзакций и строку фильтров — это уже не забота `ChartView`.
    @Binding var isFullScreen: Bool
    @Environment(PathSharedState.self) var path
    @Environment(\.calendar) var calendar
    @Binding var filters: TransactionFilters
    var currency: Currency

    // Владеем позицией/масштабом графика здесь (а не внутри Graph), чтобы при переключении
    // в полноэкранный режим и обратно (это отдельный экземпляр Graph) они не сбрасывались.
    @State private var visibleRange: Int
    @State private var xPosition: Date

    init(
        chartType: ChartType = .earningsAndExpenses,
        chartViewGroupBy: Binding<ChartViewGroupBy>,
        filters: Binding<TransactionFilters>,
        currency: Currency,
        aggregateIntoParents: Bool = true,
        isFullScreen: Binding<Bool> = .constant(false)
    ) {
        self.formatter = CurrencyFormatter(currency: currency, withUnits: false)
        self._chartViewGroupBy = chartViewGroupBy
        vm = ChartViewModel(chartType: chartType, aggregateIntoParents: aggregateIntoParents)
        self.currency = currency
        self._filters = filters
        self._isFullScreen = isFullScreen
        let defaultPeriod = ChartPeriod.month
        self._visibleRange = State(initialValue: defaultPeriod.defaultVisibleRange)
        self._xPosition = State(initialValue: Date.now.addingTimeInterval(
            TimeInterval(-1 * defaultPeriod.secondsPerUnit * defaultPeriod.defaultVisibleRange)
        ))
    }

    var formatter: CurrencyFormatter

    let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.3 // Треть экрана

    private var displayTypeIcon: String {
        chartDisplayTypeIcon(chartType: vm.chartType, displayType: chartDisplayType)
    }

    private var displayTypeLabel: String {
        chartDisplayTypeLabel(chartType: vm.chartType, displayType: chartDisplayType)
    }

    private var displayedData: [Series] {
        isSortedByAmount ? seriesSortedByAmount(vm.data, using: vm) : vm.data
    }

    /// В обычном (не полноэкранном) режиме показываем только первые несколько серий —
    /// весь список открывается через "Показать ещё", которая ведёт в полноэкранный режим.
    private let collapsedSeriesLimit = 4

    /// Сдвигает (а не расширяет) весь диапазон фильтра "От"/"До" на полгода в одну сторону —
    /// вызывается кнопками на подневном графике при достижении края загруженных данных.
    private func shiftDateRange(byMonths months: Int) {
        let effectiveDateTo = filters.dateTo ?? Date.now
        let effectiveDateFrom = filters.dateFrom ?? vm.period.defaultDateFrom(relativeTo: filters.dateTo) ?? effectiveDateTo.adding(.year, value: -1)
        filters.dateFrom = effectiveDateFrom.adding(.month, value: months)
        filters.dateTo = effectiveDateTo.adding(.month, value: months)
    }

    var body: some View {
        Group {
            if isFullScreen {
                ChartFullScreenView(
                    vm: vm,
                    chartDisplayType: $chartDisplayType,
                    chartViewGroupBy: chartViewGroupBy,
                    currency: currency,
                    formatter: formatter,
                    filters: $filters,
                    isPresented: $isFullScreen,
                    isSortedByAmount: $isSortedByAmount,
                    visibleRange: $visibleRange,
                    xPosition: $xPosition,
                    onExtendRangeEarlier: vm.period == .day ? { shiftDateRange(byMonths: -6) } : nil,
                    onExtendRangeLater: vm.period == .day ? { shiftDateRange(byMonths: 6) } : nil
                )
            } else {
                normalContent
            }
        }
        .task {
            do {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            } catch {
                alert.error(error)
            }
        }
        .onChange(of: vm.chartType) { _, newType in
            if newType != .balance && newType != .balanceTotal {
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
            visibleRange = newPeriod.defaultVisibleRange
            xPosition = Date.now.addingTimeInterval(
                TimeInterval(-1 * newPeriod.secondsPerUnit * newPeriod.defaultVisibleRange)
            )
            Task {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            }
        }
        .onChange(of: vm.aggregateIntoParents) { _, _ in
            Task {
                try await vm.load(groupBy: chartViewGroupBy, filters: filters, targetCurrency: currency)
            }
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
                if vm.chartType == .balance || vm.chartType == .balanceTotal {
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
                    if chartDisplayType == .ring && (vm.chartType == .balance || vm.chartType == .balanceTotal) {
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
                            visibleRange: $visibleRange,
                            xPosition: $xPosition,
                            currency: currency,
                            onExtendRangeEarlier: vm.period == .day ? { shiftDateRange(byMonths: -6) } : nil,
                            onExtendRangeLater: vm.period == .day ? { shiftDateRange(byMonths: 6) } : nil
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
                    } else {
                        Text(chartListHeaderLabel(chartType: vm.chartType, chartViewGroupBy: chartViewGroupBy))
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

                    Button {
                        isSortedByAmount.toggle()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Сумма")
                            if isSortedByAmount {
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                    .foregroundStyle(isSortedByAmount ? .blue : .primary)
                }
                .bold()
                LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(Array(displayedData.prefix(collapsedSeriesLimit).enumerated()), id: \.element) { (i, series) in
                        ChartListItemView(
                            chartViewGroupBy: chartViewGroupBy,
                            vm: $vm,
                            series: series,
                            currency: currency,
                            filters: $filters
                        )
                    }
                }
                .font(.callout)
                Button {
                    isFullScreen = true
                } label: {
                    HStack {
                        Text("Показать ещё")
                        Image(systemName: "chevron.down")
                    }
                    .frame(maxWidth: .infinity)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 15)
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
