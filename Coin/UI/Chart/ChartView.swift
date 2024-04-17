//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI
import Charts

struct ChartView: View {
    
    let data: [Series]
    @Environment(\.calendar) var calendar
    @Binding var rawSelectedDate: Date?
    let oneMonthRange = 60 * 60 * 24 * 30
    @State var visibleRange: Float = 60 * 60 * 24 * 30 * 6
    @State var xPosition = Date.now.addingTimeInterval(TimeInterval(-1 * 60 * 60 * 24 * 30 * 6))
    var colorPerName: [String: Color]
    
    func endOfMonth(for date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date)!
    }
    
    var maxSum: Int {
        let dateRange = xPosition...xPosition + TimeInterval(visibleRange)
        var maxValue: Int = 0
        for series in data {
            if let value = series.data.filter({ dateRange.contains($0.key) }).values.max() {
                if Double(maxValue) < value.doubleValue {
                    maxValue = Int(value.doubleValue * 1.2)
                }
            }
        }
        return maxValue
    }
    
    var selectedDate: Date? {
        if let rawSelectedDate {
            return data.first?.data.first(where: {
                let endOfMonth = endOfMonth(for: $0.key)
                
                return ($0.key ... endOfMonth).contains(rawSelectedDate)
            })?.key
        }
        
        return nil
    }
    

    
    var body: some View {
        VStack {
            Chart {
                ForEach(data, id: \.name) { series in
                    ForEach(series.data.sorted(by: >), id: \.key) { month, amount in
                        LineMark(
                            x: .value("Day", month, unit: .month),
                            y: .value("Sales", amount)
                        )
                    }
                    .foregroundStyle(by: .value("Вид", series.name))
                    .interpolationMethod(.catmullRom)
                }
                
                if let selectedDate {
                    RuleMark(
                        x: .value("Selected", selectedDate, unit: .month)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .offset(yStart: -10)
                    .zIndex(-1)
                }
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale { colorPerName[$0] ?? .white }
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(x: $xPosition)
            .chartXVisibleDomain(length: visibleRange)
            .chartYScale(domain: 0...maxSum)
            .animation(.linear(duration: 0.2), value: maxSum)
            .chartXSelection(value: $rawSelectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: visibleRange < 24 * oneMonthRange ? .month : .year)) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(format:
                                    visibleRange < 24 * oneMonthRange ? .dateTime.month(visibleRange < 12 * oneMonthRange ? .abbreviated : .narrow) : .dateTime.year(), centered: true)
                }
            }
            Text(selectedDate?.formatted(.dateTime.year(.defaultDigits).month(.wide)) ?? " ")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Stepper (
                value: $visibleRange,
                in: 6*oneMonthRange...72*oneMonthRange,
                step: oneMonthRange
            ) {
                Text("Количество месяцев для показа: \(visibleRange / oneMonthRange)")
            }
        }
    }
}

#Preview {
    ChartView(data: [], rawSelectedDate: .constant(Date.now), colorPerName: [:])
}
