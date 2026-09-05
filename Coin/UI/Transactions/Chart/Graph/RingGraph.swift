//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI
import Charts

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
