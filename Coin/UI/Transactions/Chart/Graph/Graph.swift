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
    @State private var zoomTimer: Timer?
    @State private var zoomTickCount: Int = 0
    @Binding var lastSelectedDate: Date
    // Владелец — вызывающий View (ChartView), а не сам Graph: при переключении в
    // полноэкранный режим создаётся отдельный экземпляр Graph, и если бы позиция/масштаб
    // были собственным @State, они бы каждый раз сбрасывались на дефолт.
    @Binding var visibleRange: Int
    @Binding var xPosition: Date
    let currencyFormatter: CurrencyFormatter
    // Показываются только когда заданы (сейчас — только для подневного графика, у которого
    // есть жёсткая граница загруженных данных, см. `ChartPeriod.defaultDateFrom`). Тап
    // должен раздвинуть сам фильтр по датам ещё на полгода в соответствующую сторону.
    var onExtendRangeEarlier: (() -> Void)?
    var onExtendRangeLater: (() -> Void)?

    private var unitRange: Int { period.secondsPerUnit }

    private var dataMinDate: Date? {
        data.compactMap { $0.data.keys.min() }.min()
    }

    private var dataMaxDate: Date? {
        data.compactMap { $0.data.keys.max() }.max()
    }

    // Край экрана считаем достигнутым, когда видимое окно почти вплотную подходит к
    // границе загруженных данных (с запасом в один период, чтобы не мигать на подходе).
    private var hasReachedEarliestEdge: Bool {
        guard let dataMinDate else { return false }
        return xPosition.startOfPeriod(period) <= dataMinDate + TimeInterval(unitRange)
    }

    private var hasReachedLatestEdge: Bool {
        guard let dataMaxDate else { return false }
        let windowEnd = xPosition + TimeInterval(visibleRange * unitRange)
        return windowEnd >= dataMaxDate - TimeInterval(unitRange)
    }

    // Swift Charts (BinningUnit) не поддерживает Calendar.Component.quarter — падает с
    // "Component is not supported" при биннинге меток/осей. Наши квартальные точки уже
    // выровнены по началу квартала (1 янв/апр/июл/окт), поэтому для целей отрисовки
    // квартал можно безопасно подменить на .month — сама точка от этого не сдвигается.
    private var chartUnit: Calendar.Component {
        period.calendarComponent == .quarter ? .month : period.calendarComponent
    }

    init(
        chartType: ChartType,
        period: ChartPeriod = .month,
        data: [Series],
        lastSelectedDate: Binding<Date>,
        visibleRange: Binding<Int>,
        xPosition: Binding<Date>,
        currency: Currency,
        onExtendRangeEarlier: (() -> Void)? = nil,
        onExtendRangeLater: (() -> Void)? = nil
    ) {
        self.chartType = chartType
        self.period = period
        self.data = data
        self._lastSelectedDate = lastSelectedDate
        self.currencyFormatter = CurrencyFormatter(currency: currency, withUnits: true)
        self._visibleRange = visibleRange
        self._xPosition = xPosition
        self.onExtendRangeEarlier = onExtendRangeEarlier
        self.onExtendRangeLater = onExtendRangeLater
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
        // Дельта считается так же, как баланс: может уходить в минус, и границы должны
        // подстраиваться и снизу, и сверху (не просто от нуля).
        if chartType == .balance || chartType == .balanceTotal || chartType == .delta {
            return balanceRangeBounds.max
        }
        var maxValue: Double = 0
        let range = scalingDateRange

        switch chartType {
        case .earnings, .expenses:
            // Как и для баланса — нельзя генерировать даты циклом и сравнивать на точное
            // равенство с ключами `series.data` (см. `balanceRangeBounds`): при рассинхроне
            // календаря это давало maxValue=0 на каждой итерации, и график схлопывался до
            // запасного домена 0...1 при скролле. Считаем сумму по реальным ключам, которые
            // попадают в видимый диапазон.
            var sumsByDate: [Date: Double] = [:]
            for series in data {
                for (date, amount) in series.data where range.contains(date) {
                    sumsByDate[date, default: 0] += amount.doubleValue
                }
            }
            if let value = sumsByDate.values.max(), maxValue < value {
                maxValue = value
            }

        case .earningsAndExpenses:
            for series in data {
                if let value = series.data.filter({ range.contains($0.key) }).values.max() {
                    if maxValue < value.doubleValue {
                        maxValue = value.doubleValue
                    }
                }
            }

        case .balance, .balanceTotal, .delta:
            break
        }
        if maxValue == 0 {
            maxValue = 1
        }
        return maxValue * 1.1
    }

    /// Минимум нужен для баланса и дельты — оба могут уходить в минус, и в отличие от
    /// доходов/расходов там нельзя просто отталкиваться от нуля.
    var minSum: Double {
        guard chartType == .balance || chartType == .balanceTotal || chartType == .delta else { return 0 }
        return balanceRangeBounds.min
    }

    /// Красит линию дельты по знаку значения: зелёная выше нуля, красная ниже. Строится как
    /// вертикальный градиент с резким переходом ровно на позиции y=0 внутри текущего домена
    /// (minSum...maxSum) — Charts применяет градиент в системе координат значений, а не
    /// точек линии, поэтому цвет остаётся верным в любой точке independent от масштаба/скролла,
    /// включая случаи с несколькими пересечениями нуля.
    private var deltaZeroCrossingGradient: LinearGradient {
        let range = maxSum - minSum
        guard range > 0 else {
            return LinearGradient(colors: [minSum >= 0 ? .green : .red], startPoint: .top, endPoint: .bottom)
        }
        let zeroLocation = min(max((maxSum - 0) / range, 0), 1)
        return LinearGradient(
            stops: [
                .init(color: .green, location: 0),
                .init(color: .green, location: zeroLocation),
                .init(color: .red, location: zeroLocation),
                .init(color: .red, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Chart {
                    ForEach(Array(data.reversed().enumerated()), id: \.element) { (i, series) in
                        // Для столбчатого графика (баланс) нулевые точки не добавляют ничего
                        // визуально — не рисуем их вообще, чтобы не тратить память/время на
                        // лишние BarMark при большом количестве периодов.
                        let seriesEntries = (chartType == .balance || chartType == .balanceTotal)
                            ? series.data.filter { $0.value != 0 }
                            : series.data
                        ForEach(seriesEntries.sorted(by: >), id: \.key) { month, amount in
                            if chartType == .delta {
                                LineMark(
                                    x: .value("Период", month, unit: chartUnit),
                                    y: .value("Сумма", amount)
                                )
                                .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .foregroundStyle(deltaZeroCrossingGradient)
                            } else if chartType == .earningsAndExpenses {
                                LineMark(
                                    x: .value("Период", month, unit: chartUnit),
                                    y: .value("Сумма", amount)
                                )
                                .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            } else if chartType == .balance || chartType == .balanceTotal {
                                // Накопительная площадь плохо читается с отрицательными значениями —
                                // для баланса используем столбцы, которые могут уходить ниже нуля.
                                BarMark(
                                    x: .value("Период", month, unit: chartUnit),
                                    y: .value("Сумма", amount)
                                )
                            } else {
                                AreaMark(
                                    x: .value("Период", month, unit: chartUnit),
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
                        x: .value("Selected", lastSelectedDate, unit: chartUnit)
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
                        // Charts не умеет бинить по .quarter — данные и так лежат по началам
                        // кварталов (1 янв/апр/июл/окт), поэтому просто шагаем по 3 месяца.
                        AxisMarks(values: .stride(by: .month, count: 3)) { _ in
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
                // Кнопки-"подгрузчики": показываются, только если вызывающий экран их передал
                // (сейчас — только подневный график, у которого есть жёсткая граница
                // загруженных данных), и только когда экран действительно доскроллен до края.
                .overlay(alignment: .leading) {
                    if let onExtendRangeEarlier, hasReachedEarliestEdge {
                        Button(action: onExtendRangeEarlier) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.blue, Color(.systemBackground))
                        }
                        .padding(.leading, 4)
                    }
                }
                .overlay(alignment: .trailing) {
                    if let onExtendRangeLater, hasReachedLatestEdge {
                        Button(action: onExtendRangeLater) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.blue, Color(.systemBackground))
                        }
                        .padding(.trailing, 4)
                    }
                }
                if !data.isEmpty {
                    // Границы масштабирования не должны зависеть от количества точек в данных —
                    // иначе при малом количестве точек (например, у графика баланса) верхняя
                    // граница совпадает со стартовым значением, и кнопки перестают что-либо делать.
                    VStack {
                        ScaleButton(imageName: "plus")
                            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
                                if isPressing {
                                    performZoomStep(direction: -1)
                                    startZoomRepeat(direction: -1)
                                } else {
                                    stopZoomRepeat()
                                }
                            }, perform: {})
                        ScaleButton(imageName: "minus")
                            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
                                if isPressing {
                                    performZoomStep(direction: 1)
                                    startZoomRepeat(direction: 1)
                                } else {
                                    stopZoomRepeat()
                                }
                            }, perform: {})
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

    /// Кнопки +/- раньше меняли только `visibleRange`, оставляя `xPosition` нетронутым —
    /// Charts' внутреннее состояние скролла и наш `scalingDateRange` расходились до первого
    /// ручного скролла (только он реально протаскивает свежий `xPosition` через биндинг),
    /// из-за чего автоскейл Y иногда не учитывал только что открывшуюся часть графика.
    /// Явно пересчитываем `xPosition`, удерживая правый край окна на месте — это и даёт
    /// привычное поведение зума, и гарантированно синхронизирует оба состояния сразу.
    private func zoom(by delta: Int) {
        let oldRightEdge = xPosition + TimeInterval(visibleRange * unitRange)
        visibleRange += delta
        xPosition = oldRightEdge - TimeInterval(visibleRange * unitRange)
    }

    private func performZoomStep(direction: Int) {
        if direction < 0 {
            if visibleRange > 2 {
                zoom(by: -1)
            }
        } else {
            if visibleRange < 120 {
                zoom(by: 1)
            }
        }
    }

    /// Долгое удержание +/- зумит в ускоренном режиме: интервал между шагами сокращается
    /// по мере удержания, вплоть до минимального.
    private func startZoomRepeat(direction: Int) {
        stopZoomRepeat()
        scheduleNextZoomTick(direction: direction)
    }

    private func scheduleNextZoomTick(direction: Int) {
        let interval = max(0.03, 0.35 - Double(zoomTickCount) * 0.03)
        zoomTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            performZoomStep(direction: direction)
            zoomTickCount += 1
            scheduleNextZoomTick(direction: direction)
        }
    }

    private func stopZoomRepeat() {
        zoomTimer?.invalidate()
        zoomTimer = nil
        zoomTickCount = 0
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

