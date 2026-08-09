//
//  ChartFullScreenView.swift
//  Coin
//

import SwiftUI

/// Полноэкранный режим просмотра графика: график зафиксирован сверху, строка "Всего"
/// зафиксирована снизу, а между ними — тот же список серий, что и в обычном режиме.
/// Лейблы фильтров, переключатель вида графика и выбор периода остаются на месте —
/// пропадает только список транзакций.
struct ChartFullScreenView: View {

    @Bindable var vm: ChartViewModel
    @Binding var chartDisplayType: ChartDisplayType
    var chartViewGroupBy: ChartViewGroupBy
    var currency: Currency
    var formatter: CurrencyFormatter
    @Binding var filters: TransactionFilters
    @Binding var isPresented: Bool
    @Binding var isSortedByAmount: Bool

    private var displayTypeIcon: String {
        chartDisplayTypeIcon(chartType: vm.chartType, displayType: chartDisplayType)
    }

    private var displayTypeLabel: String {
        chartDisplayTypeLabel(chartType: vm.chartType, displayType: chartDisplayType)
    }

    private var displayedData: [Series] {
        isSortedByAmount ? seriesSortedByAmount(vm.data, using: vm) : vm.data
    }

    var body: some View {
        VStack(spacing: 0) {
            TransactionFiltersRowView(filters: $filters)

            Picker(vm.chartType.name, selection: $vm.chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.name)
                        .tag(type)
                }
            }
            .padding(.horizontal)

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
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                Spacer()
                // На месте кнопки "развернуть" — кнопка "свернуть" в той же позиции,
                // но крупнее и в стилистике системной круглой кнопки закрытия (как в шитах).
                // В самом HStack, а не в overlay — иначе при пустой строке (earningsAndExpenses)
                // кнопка выходила за пределы своей строки и перекрывала пикер периода снизу.
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
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
            .frame(height: UIScreen.main.bounds.height * 0.35)

            if !vm.data.isEmpty {
                VStack {
                    HStack {
                        if vm.chartType == .earnings || vm.chartType == .expenses {
                            Text(chartViewGroupBy.name)
                                .font(.caption)
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
                                ForEach(ChartViewModel.AggregationMethod.allCases.filter {
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
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible()), GridItem(.flexible())]) {
                            ForEach(Array(displayedData.enumerated()), id: \.element) { (i, series) in
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
                }
                .font(.callout)
                .padding(.horizontal, 15)
                // Список серий должен занимать только оставшееся место и скроллиться сам —
                // иначе при большом количестве серий он раздвигает контейнер и "Всего" внизу
                // уезжает за пределы экрана.
                .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("Нет данных для отображения")
                    .foregroundStyle(.secondary)
                Spacer()
            }

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
                .font(.title3.bold())
                .padding()
            }
        }
    }
}
