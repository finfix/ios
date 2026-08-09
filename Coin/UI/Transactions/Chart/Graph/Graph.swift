//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI
import Charts

let defaultColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .brown, .cyan, .indigo, .mint, .pink, .teal]

struct Graph: View {
    
    var chartType: ChartType
    var period: ChartPeriod
    let data: [Series]
    @Environment(\.calendar) var calendar
    @State private var rawSelectedDate: Date?
    @Binding var lastSelectedDate: Date
    @State var visibleRange: Int
    @State var xPosition: Date
    let currencyFormatter: CurrencyFormatter
    
    private var unitRange: Int { period.secondsPerUnit }
    
    init(
        chartType: ChartType,
        period: ChartPeriod = .month,
        data: [Series],
        lastSelectedDate: Binding<Date>,
        currency: Currency
    ) {
        self.chartType = chartType
        self.period = period
        self.data = data
        self._lastSelectedDate = lastSelectedDate
        self.currencyFormatter = CurrencyFormatter(currency: currency, withUnits: true)
        self._visibleRange = State(initialValue: period.defaultVisibleRange)
        self._xPosition = State(initialValue: Date.now.addingTimeInterval(
            TimeInterval(-1 * period.secondsPerUnit * period.defaultVisibleRange)
        ))
    }
    
    /// Диапазон дат, который должен учитываться при автоскейлинге: то, что видно на экране
    /// (от `xPosition` до `xPosition + visibleRange*unitRange`), плюс ровно одна скрытая
    /// точка с каждой стороны — чтобы график не "прыгал" по масштабу при скролле на один шаг.
    private var scalingDateRange: ClosedRange<Date> {
        let windowStart = xPosition.startOfPeriod(period)
        let windowEnd = xPosition + TimeInterval(visibleRange * unitRange)
        return (windowStart - TimeInterval(unitRange))...(windowEnd + TimeInterval(unitRange))
    }

    /// Для баланса ось не должна упираться в ноль: автоскейлим и по нижней, и по верхней
    /// границе от реальных значений в видимом диапазоне (плюс запас по обеим сторонам).
    ///
    /// Важно: тут нельзя генерировать даты циклом и сравнивать их на точное равенство
    /// с ключами `series.data` — из-за несовпадения календарной привязки (часовой пояс,
    /// день месяца и т.п.) точного совпадения могло вообще не быть ни на одной итерации,
    /// из-за чего суммы всегда получались нулевыми, а автоскейл откатывался на
    /// бессмысленный запасной диапазон. Вместо этого просто суммируем реальные ключи,
    /// попадающие в видимый диапазон.
    ///
    /// Ещё важно: BarMark по умолчанию стекует сегменты по x — положительные счета растут
    /// вверх от нуля, отрицательные вниз от нуля, независимо друг от друга. Поэтому нельзя
    /// брать чистую сумму (положительные + отрицательные) на дату — из-за взаимной
    /// компенсации она может оказаться близкой к нулю, даже когда сам столбик проваливается
    /// далеко вниз. Считаем сумму положительных и сумму отрицательных сегментов раздельно —
    /// это и есть верх и низ фактического стека.
    private var balanceRangeBounds: (min: Double, max: Double) {
        let range = scalingDateRange
        var positiveSumsByDate: [Date: Double] = [:]
        var negativeSumsByDate: [Date: Double] = [:]
        for series in data {
            for (date, amount) in series.data where range.contains(date) {
                let value = amount.doubleValue
                if value >= 0 {
                    positiveSumsByDate[date, default: 0] += value
                } else {
                    negativeSumsByDate[date, default: 0] += value
                }
            }
        }
        guard !positiveSumsByDate.isEmpty || !negativeSumsByDate.isEmpty else {
            return (0, 1)
        }
        let maxValue = positiveSumsByDate.values.max() ?? 0
        let minValue = negativeSumsByDate.values.min() ?? 0
        let span = maxValue - minValue
        let padding = span == 0 ? max(abs(maxValue), 1) * 0.1 : span * 0.1
        return (minValue - padding, maxValue + padding)
    }

    var maxSum: Double {
        if chartType == .balance {
            return balanceRangeBounds.max
        }
        var maxValue: Double = 0
        let range = scalingDateRange

        switch chartType {
        case .earnings, .expenses:
            var currentDate: Date = range.lowerBound

            while currentDate <= range.upperBound {
                let sumOfSeriesOnDate: Double = (data.map { $0.data.filter( { $0.key == currentDate } ).values.reduce(0) { $0 + $1 } }.reduce(0) { $0 + $1 }).doubleValue
                if maxValue < sumOfSeriesOnDate {
                    maxValue = sumOfSeriesOnDate
                }
                currentDate = currentDate.adding(period.calendarComponent, value: 1)
            }

        case .earningsAndExpenses:
            for series in data {
                if let value = series.data.filter({ range.contains($0.key) }).values.max() {
                    if maxValue < value.doubleValue {
                        maxValue = value.doubleValue
                    }
                }
            }

        case .balance:
            break
        }
        if maxValue == 0 {
            maxValue = 1
        }
        return maxValue * 1.1
    }

    /// Минимум нужен только для баланса — он может уходить в минус, и в отличие от
    /// доходов/расходов там нельзя просто отталкиваться от нуля.
    var minSum: Double {
        guard chartType == .balance else { return 0 }
        return balanceRangeBounds.min
    }

    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Chart {
                    ForEach(Array(data.reversed().enumerated()), id: \.element) { (i, series) in
                        // Для столбчатого графика (баланс) нулевые точки не добавляют ничего
                        // визуально — не рисуем их вообще, чтобы не тратить память/время на
                        // лишние BarMark при большом количестве периодов.
                        let seriesEntries = chartType == .balance
                            ? series.data.filter { $0.value != 0 }
                            : series.data
                        ForEach(seriesEntries.sorted(by: >), id: \.key) { month, amount in
                            if chartType == .earningsAndExpenses {
                                LineMark(
                                    x: .value("Период", month, unit: period.calendarComponent),
                                    y: .value("Сумма", amount)
                                )
                                .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            } else if chartType == .balance {
                                // Накопительная площадь плохо читается с отрицательными значениями —
                                // для баланса используем столбцы, которые могут уходить ниже нуля.
                                BarMark(
                                    x: .value("Период", month, unit: period.calendarComponent),
                                    y: .value("Сумма", amount)
                                )
                            } else {
                                AreaMark(
                                    x: .value("Период", month, unit: period.calendarComponent),
                                    y: .value("Сумма", amount),
                                    stacking: .standard
                                )
                                .opacity(0.8)
                            }
                        }
                        .foregroundStyle(by: .value("Категория", i))
                        .interpolationMethod(period == .day || period == .week ? .linear : .linear)
                    }
                    
                    RuleMark(
                        x: .value("Selected", lastSelectedDate, unit: period.calendarComponent)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .offset(yStart: -10)
                    .zIndex(-1)
                }
                .chartLegend(.hidden)
                .chartForegroundStyleScale { data.reversed()[$0].color }
                .chartScrollableAxes(.horizontal)
                .chartScrollPosition(x: $xPosition)
                .chartXVisibleDomain(length: visibleRange * unitRange)
                .chartYScale(domain: minSum...maxSum)
                .chartXSelection(value: $rawSelectedDate)
                .chartXAxis {
                    switch period {
                    case .day:
                        AxisMarks(values: .stride(by: .day, count: max(1, visibleRange / 7))) { _ in
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        }
                    case .week:
                        AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        }
                    case .month:
                        AxisMarks(values: .stride(by: visibleRange < 24 ? .month : .year)) { _ in
                            AxisTick()
                            AxisValueLabel(format: visibleRange < 24 ?
                                .dateTime.month(visibleRange < 12 ? .abbreviated : .narrow) :
                                    .dateTime.year(), centered: true)
                        }
                    case .quarter:
                        AxisMarks(values: .stride(by: .quarter)) { _ in
                            AxisTick()
                            AxisValueLabel(format: .dateTime.year().month(.abbreviated), centered: true)
                        }
                    case .year:
                        AxisMarks(values: .stride(by: .year)) { _ in
                            AxisTick()
                            AxisValueLabel(format: .dateTime.year(), centered: true)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .inset, position: .leading, values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel() {
                            if let decimalValue = value.as(Decimal.self) {
                                Text(currencyFormatter.string(number: decimalValue))
                            }
                        }
                    }
                }
                if !data.isEmpty {
                    // Границы масштабирования не должны зависеть от количества точек в данных —
                    // иначе при малом количестве точек (например, у графика баланса) верхняя
                    // граница совпадает со стартовым значением, и кнопки перестают что-либо делать.
                    VStack {
                        Button {
                            if visibleRange > 2 {
                                visibleRange -= 1
                            }
                        } label: {
                            ScaleButton(imageName: "plus")
                        }
                        Button {
                            if visibleRange < 120 {
                                visibleRange += 1
                            }
                        } label: {
                            ScaleButton(imageName: "minus")
                        }
                    }
                    .padding(.trailing, 25)
                    .padding(.bottom, 40)
                    .opacity(0.7)
                }
            }
            Text(period.selectedDateLabel(for: lastSelectedDate))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onChange(of: rawSelectedDate) { _, newValue in
            if let newValue {
                let startOfPeriod = newValue.startOfPeriod(period)
                lastSelectedDate = startOfPeriod
            }
        }
    }
}

struct RingGraph: View {
    
    let data: [Series]
    let period: ChartPeriod
    @Binding var lastSelectedDate: Date
    let currencyFormatter: CurrencyFormatter
    
    init(data: [Series], period: ChartPeriod = .month, lastSelectedDate: Binding<Date>, currency: Currency) {
        self.data = data
        self.period = period
        self._lastSelectedDate = lastSelectedDate
        self.currencyFormatter = CurrencyFormatter(currency: currency, withUnits: true)
    }
    
    var minDate: Date {
        data.compactMap { $0.data.keys.min() }.min() ?? lastSelectedDate
    }
    
    var maxDate: Date {
        data.compactMap { $0.data.keys.max() }.max() ?? lastSelectedDate
    }
    
    var totalForSelectedDate: Decimal {
        data.map { $0.data[lastSelectedDate] ?? 0 }.reduce(0, +)
    }
    
    // Серии с ненулевым значением для выбранного периода
    var visibleData: [Series] {
        data.filter { ($0.data[lastSelectedDate] ?? 0) > 0 }
    }
    
    var body: some View {
        ZStack {
            if !visibleData.isEmpty {
                Chart {
                    ForEach(visibleData) { series in
                        SectorMark(
                            angle: .value("Сумма", (series.data[lastSelectedDate] ?? 0).doubleValue),
                            innerRadius: .ratio(0.62),
                            angularInset: 2
                        )
                        .foregroundStyle(series.color)
                    }
                }
                .chartLegend(.hidden)
            } else {
                // Пустое кольцо когда нет данных
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 30)
            }
            
            // Центр: итоговая сумма и месяц
            VStack(spacing: 4) {
                Text(currencyFormatter.string(number: totalForSelectedDate))
                    .font(.headline)
                    .bold()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(period.selectedDateLabel(for: lastSelectedDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(80)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if value.translation.width < 0 {
                            // Свайп влево — следующий период
                            let nextDate = lastSelectedDate.adding(period.calendarComponent, value: 1)
                            if nextDate <= maxDate {
                                lastSelectedDate = nextDate
                            }
                        } else {
                            // Свайп вправо — предыдущий период
                            let prevDate = lastSelectedDate.adding(period.calendarComponent, value: -1)
                            if prevDate >= minDate {
                                lastSelectedDate = prevDate
                            }
                        }
                    }
                }
        )
    }
}

struct ScaleButton: View {
    
    let imageName: String
    
    var body: some View {
        Circle()
            .frame(width: 30, height: 30)
            .foregroundColor(.gray)
            .overlay {
                Image(systemName: imageName)
                    .foregroundColor(.black)
                    .font(.system(size: 15))
            }
    }
}

#Preview {
    ChartView(
        chartViewGroupBy: .constant(ChartViewGroupBy.byAccount),
        filters: .constant(TransactionFilters(accountGroups: [])),
        currency: Currency(
            symbol: "₽"
        )
    )
        .environment(AlertManager(handle: {_ in }))
}

