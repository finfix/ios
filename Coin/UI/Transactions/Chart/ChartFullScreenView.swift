//
//  ChartFullScreenView.swift
//  Coin
//

import SwiftUI

/// Полноэкранный режим просмотра графика: график зафиксирован сверху, строка "Всего"
/// зафиксирована снизу, а между ними — тот же список серий, что и в обычном режиме.
struct ChartFullScreenView: View {

    @Bindable var vm: ChartViewModel
    var chartDisplayType: ChartDisplayType
    var chartViewGroupBy: ChartViewGroupBy
    var currency: Currency
    var formatter: CurrencyFormatter
    @Binding var filters: TransactionFilters
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(vm.chartType.name)
                    .font(.headline)
                Spacer()
                Image(systemName: "xmark")
                    .opacity(0)
            }
            .padding()

            Group {
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
            }
            .padding(.horizontal)
            .frame(height: UIScreen.main.bounds.height * 0.35)

            if !vm.data.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(Array(vm.data.enumerated()), id: \.element) { (i, series) in
                            ChartListItemView(
                                chartViewGroupBy: chartViewGroupBy,
                                vm: Binding(get: { vm }, set: { _ in }),
                                series: series,
                                currency: currency,
                                filters: $filters
                            )
                        }
                    }
                }
                .font(.callout)
                .padding(.horizontal, 15)
            } else {
                Spacer()
                Text("Нет данных для отображения")
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if !vm.data.isEmpty {
                let totalLabel = vm.chartType == .balance ? "Итого" : "Всего"
                let selectedDateTotal = vm.totalBySelectedDate
                Divider()
                HStack {
                    Text(totalLabel)
                    Spacer()
                    Text(formatter.string(number: selectedDateTotal))
                }
                .font(.title3.bold())
                .padding()
            }
        }
    }
}
