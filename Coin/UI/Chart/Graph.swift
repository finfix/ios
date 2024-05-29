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
    let data: [Series]
    @Environment(\.calendar) var calendar
    @State private var rawSelectedDate: Date?
    @Binding var lastSelectedDate: Date
    let oneMonthRange = 60 * 60 * 24 * 30
    @State var visibleRange = 6
    @State var xPosition = Date.now.addingTimeInterval(TimeInterval(-1 * 60 * 60 * 24 * 30 * 6))
    let currencyFormatter: CurrencyFormatter
    
    init(
        chartType: ChartType,
        data: [Series],
        lastSelectedDate: Binding<Date>,
        accountGroup: AccountGroup
    ) {
        self.chartType = chartType
        self.data = data
        self._lastSelectedDate = lastSelectedDate
        self.currencyFormatter = CurrencyFormatter(currency: accountGroup.currency, withUnits: true)
    }
    
    var maxSum: Double {
        var maxValue: Double = 0
        
        switch chartType {
        case .earnings, .expenses:
            let maxDate: Date = xPosition + TimeInterval((visibleRange + 1) * oneMonthRange)
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
            let dateRange = xPosition-TimeInterval(oneMonthRange)...xPosition + TimeInterval((visibleRange+1)*oneMonthRange)
            
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
            ZStack(alignment: .bottomTrailing) {
                Chart {
                    ForEach(Array(data.reversed().enumerated()), id: \.element) { (i, series) in
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
                                .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            }
                        }
                        .foregroundStyle(by: .value("Категория", i))
                        .interpolationMethod(.catmullRom) // TODO: что-то с ним придумать
                    }
                    
                    RuleMark(
                        x: .value("Selected", lastSelectedDate, unit: .month)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .offset(yStart: -10)
                    .zIndex(-1)
                }
                .chartLegend(.hidden)
                .chartForegroundStyleScale { data.reversed()[$0].color }
                .chartScrollableAxes(.horizontal)
                .chartScrollPosition(x: $xPosition)
                .chartXVisibleDomain(length: visibleRange*oneMonthRange)
                .chartYScale(domain: 0...maxSum)
                .chartXSelection(value: $rawSelectedDate)
                .chartXAxis {
                    AxisMarks(values: .stride(by: visibleRange < 24 ? .month : .year)) { _ in
                        AxisTick()
                        AxisValueLabel(format: visibleRange < 24 ?
                            .dateTime.month(visibleRange < 12 ? .abbreviated : .narrow) :
                                .dateTime.year(), centered: true)
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
                if let firstSeries = data.first {
                    VStack {
                        Button {
                            if 2 < visibleRange {
                                visibleRange -= 1
                            }
                        } label: {
                            ScaleButton(imageName: "plus")
                        }
                        Button {
                            if visibleRange < firstSeries.data.count+2 {
                                visibleRange += 1
                            }
                        } label: {
                            ScaleButton(imageName: "minus")
                        }
                    }
                    .padding(.trailing, 25)
                    .padding(.bottom, 40)
                    .opacity(0.5)
                }
            }
            Text(lastSelectedDate.formatted(.dateTime.year(.defaultDigits).month(.wide)))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onChange(of: rawSelectedDate) { _, newValue in
            if let newValue {
                lastSelectedDate = newValue.startOfMonth(inUTC: true)
            }
        }
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
        selectedAccountGroup: AccountGroup(
            id: 4,
            currency:
                Currency(
                    symbol: "₽"
                )
        ),
        filters: TransactionFilters()
    )
        .environment(AlertManager(handle: {_ in }))
}

