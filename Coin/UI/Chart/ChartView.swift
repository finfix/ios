//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

enum ChartViewRoute: Hashable {
    case transactionList(account: Account)
    case transactionList1(chartType: ChartType)
}

struct ChartView: View {
    @Environment(AlertManager.self) private var alert
    var selectedAccountGroup: AccountGroup
    @State private var vm: ChartViewModel
    @Environment(PathSharedState.self) var path
    @Environment(\.calendar) var calendar
    
    init(
        chartType: ChartType = .earningsAndExpenses,
        selectedAccountGroup: AccountGroup,
        filters: TransactionFilters
    ) {
        var chartType = chartType
        self.formatter = CurrencyFormatter(currency: selectedAccountGroup.currency, withUnits: false)
        self.selectedAccountGroup = selectedAccountGroup
        if let account = filters.account {
            switch account.type {
            case .earnings:
                chartType = .earnings
            case .expense:
                chartType = .expenses
            default: break
            }
        }
        vm = ChartViewModel(chartType: chartType, filters: filters)
    }
    
    var formatter: CurrencyFormatter
    
    let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.3 // Треть экрана
    
    var body: some View {
        VStack {
            Picker(vm.chartType.rawValue, selection: $vm.chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            Group {
                if !vm.data.isEmpty {
                    Graph(
                        chartType: vm.chartType,
                        data: vm.data,
                        lastSelectedDate: $vm.lastSelectedDate,
                        accountGroup: selectedAccountGroup
                    )
                } else {
                    Text("Нет данных для отображения")
                }
            }
            .frame(height: chartHeight)
            VStack {
                HStack {
                    HStack {
                        Text("Категория")
                        Spacer()
                    }
                    .frame(minWidth: 150)
                    ZStack {
                        // Custom picker label
                        HStack {
                            Spacer()
                            Text(vm.aggregationMethod.rawValue)
                                .foregroundColor(.blue)
                        }
                        
                        // Invisible picker
                        Picker("", selection: $vm.aggregationMethod) {
                            ForEach(ChartViewModel.AggregationMethod.allCases.filter{
                                vm.chartType == .earningsAndExpenses
                                ? ($0 != .percent && $0 != .budget)
                                : true
                            }, id: \.self) { method in
                                Text(method.rawValue)
                                    .tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .opacity(0.025)
                    }
                    HStack {
                        Spacer()
                        Text("Сумма")
                    }
                }
                .bold()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(Array(vm.data.enumerated()), id: \.element) { (i, series) in
                            Button {
                                if let account = series.account {
                                    path.path.append(ChartViewRoute.transactionList(account: account))
                                }
                                switch series.type {
                                case "Расход":
                                    path.path.append(ChartViewRoute.transactionList1(chartType: .expenses))
                                case "Доход":
                                    path.path.append(ChartViewRoute.transactionList1(chartType: .earnings))
                                default: break
                                }
                            } label: {
                                HStack {
                                    Text(series.account != nil ? series.account!.name : series.type)
                                        .foregroundStyle(series.color)
                                        .frame(height: 30)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            HStack {
                                Spacer()
                                if vm.aggregationMethod == .percent {
                                    Text(vm.aggregationInformation[series.id] ?? 0, format: .percent.precision(.fractionLength(0)))
                                } else {
                                    Text(formatter.string(number: vm.aggregationInformation[series.id] ?? 0))
                                }
                            }
                            .foregroundStyle(.secondary)
                            HStack {
                                Spacer()
                                Text(formatter.string(number: series.data[vm.lastSelectedDate] ?? 0))
                            }
                        }
                    }
                }
                .font(.callout)
                if vm.chartType != .earningsAndExpenses {
                    HStack {
                        Text("Всего:")
                        Spacer()
                        Text(formatter.string(number: vm.totalBySelectedDate))
                    }
                    .padding(.top)
                    .font(.title2)
                }
            }
            .padding(.horizontal, 15)
        }
        .task {
            do {
                try await vm.load(accountGroupID: selectedAccountGroup.id)
            } catch {
                alert(error)
            }
        }
        .onChange(of: selectedAccountGroup) { _, _ in
            Task {
                try await vm.load(accountGroupID: selectedAccountGroup.id)
            }
        }
        .onChange(of: vm.chartType) { _, _ in
            Task {
                try await vm.load(accountGroupID: selectedAccountGroup.id)
            }
        }
    }
}

#Preview {
    ChartView(
        chartType: .expenses, 
        selectedAccountGroup: 
            AccountGroup(
                id: 5,
                currency:
                    Currency(
                        symbol: "₽"
                    )
            ),
        filters: TransactionFilters()
    )
        .environment(AlertManager(handle: {_ in }))
}
