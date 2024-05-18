//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI
import Charts

let defaultColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .brown, .cyan, .indigo, .mint, .pink, .teal]

struct ChartView: View {
    
    var chartType: ChartType
    let data: [Series]
    @Environment(\.calendar) var calendar
    @State private var rawSelectedDate: Date?
    @Binding var lastSelectedDate: Date
    let oneMonthRange = 60 * 60 * 24 * 30
    @State var visibleRange = 60 * 60 * 24 * 30 * 6
    @State var xPosition = Date.now.addingTimeInterval(TimeInterval(-1 * 60 * 60 * 24 * 30 * 6))
    
    var maxSum: Double {
        var maxValue: Double = 0
        
        switch chartType {
        case .earnings, .expenses:
            let maxDate: Date = xPosition + TimeInterval(visibleRange + oneMonthRange)
            var currentDate: Date = (xPosition - TimeInterval(oneMonthRange)).startOfMonth(inUTC: true)
            
            while true {
                if currentDate > maxDate {
                    break
                }
                let sumOfSeriesOnDate: Double = (data.map { $0.data.filter( { $0.key == currentDate } ).values.reduce(0) { $0 + $1 } }.reduce(0) { $0 + $1 }).doubleValue
                if maxValue < sumOfSeriesOnDate {
                    maxValue = sumOfSeriesOnDate
                }
                currentDate = currentDate.adding(.month, value: 1)
            }
            
        case .earningsAndExpenses:
            let dateRange = xPosition...xPosition + TimeInterval(visibleRange)
            
            for series in data {
                if let value = series.data.filter({ dateRange.contains($0.key) }).values.max() {
                    if maxValue < value.doubleValue {
                        maxValue = value.doubleValue
                    }
                }
            }
        }
        if maxValue == 0 {
            maxValue = 1
        }
        return maxValue * 1.1
    }
    
    var body: some View {
        VStack {
            Chart {
                ForEach(Array(data.enumerated()), id: \.element) { (i, series) in
                    ForEach(series.data.sorted(by: >), id: \.key) { month, amount in
                        if chartType != .earningsAndExpenses {
                            AreaMark(
                                x: .value("Период", month, unit: .month),
                                y: .value("Сумма", amount),
                                stacking: .standard
                            )
                            .opacity(0.8)
                        } else {
                            LineMark(
                                x: .value("Период", month, unit: .month),
                                y: .value("Сумма", amount)
                            )
                        }
                    }
                    .foregroundStyle(by: .value("Категория", i))
                    .interpolationMethod(.monotone)
                }
                
                RuleMark(
                    x: .value("Selected", lastSelectedDate, unit: .month)
                )
                .foregroundStyle(Color.gray.opacity(0.3))
                .offset(yStart: -10)
                .zIndex(-1)
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale { data[$0].color }
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(x: $xPosition)
            .chartXVisibleDomain(length: visibleRange)
            .chartYScale(domain: 0...maxSum)
            .chartXSelection(value: $rawSelectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: visibleRange < 24 * oneMonthRange ? .month : .year)) { _ in
                    AxisTick()
                    AxisValueLabel(format:
                                    visibleRange < 24 * oneMonthRange ? 
                        .dateTime.month(visibleRange < 12 * oneMonthRange ? .abbreviated : .narrow) :
                        .dateTime.year(), centered: true)
                }
            }
            .chartYAxis {
//                AxisValueLabel(format: CurrencyFormatter())
//                AxisMarks(values: .automatic(desiredCount: 4))
                AxisMarks(preset: .inset)
            }
            Text(lastSelectedDate.formatted(.dateTime.year(.defaultDigits).month(.wide)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let firstSeries = data.first {
                Stepper (
                    value: $visibleRange,
                    in: 2 * oneMonthRange...(firstSeries.data.count + 2) * oneMonthRange,
                    step: oneMonthRange
                ) {
                    Text("Количество месяцев для показа: \(visibleRange / oneMonthRange)")
                }
            }
        }
        .onChange(of: rawSelectedDate) { _, newValue in
            if let newValue {
                lastSelectedDate = newValue.startOfMonth(inUTC: true)
            }
        }
    }
}

#Preview {
    ChartTab(
        selectedAccountGroup: AccountGroup(id: 5, currency: Currency(symbol: "₽")),
        path: .constant(NavigationPath())
    )
        .environment(AlertManager(handle: {_ in }))
}
