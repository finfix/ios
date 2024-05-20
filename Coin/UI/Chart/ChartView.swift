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
    @Binding var path: NavigationPath
    @State var lastSelectedDate: Date = Date.now.startOfMonth(inUTC: true)
    @Environment(\.calendar) var calendar
    
    init(
        chartType: ChartType = .earningsAndExpenses,
        selectedAccountGroup: AccountGroup,
        account: Account? = nil,
        path: Binding<NavigationPath>
    ) {
        var chartType = chartType
        self.formatter = CurrencyFormatter(currency: selectedAccountGroup.currency, withUnits: false)
        self.selectedAccountGroup = selectedAccountGroup
        self._path = path
        if let account {
            switch account.type {
            case .earnings:
                chartType = .earnings
            case .expense:
                chartType = .expenses
            default: break
            }
        }
        vm = ChartViewModel(chartType: chartType, account: account)
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
                        lastSelectedDate: $lastSelectedDate,
                        accountGroup: selectedAccountGroup
                    )
                } else {
                    Text("Нет данных для отображения")
                }
            }
            .frame(height: chartHeight)
            List {
                ForEach(Array(vm.data.enumerated()), id: \.element) { (i, series) in
                    Button {
                        if let account = series.account {
                            path.append(ChartViewRoute.transactionList(account: account))
                        }
                        switch series.type {
                        case "Расход":
                            path.append(ChartViewRoute.transactionList1(chartType: .expenses))
                        case "Доход":
                            path.append(ChartViewRoute.transactionList1(chartType: .earnings))
                        default: break
                        }
                    } label: {
                        HStack {
                            Text(series.account != nil ? series.account!.name : series.type)
                                .foregroundStyle(series.color)
                            Spacer()
                            Text(formatter.string(number: series.data[lastSelectedDate] ?? 0))
                        }
                        .frame(minHeight: 35)
                        .bold(false)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 15)
            }
            if vm.chartType != .earningsAndExpenses {
                HStack {
                    Text("Всего:")
                    Spacer()
                    Text(formatter.string(number: vm.data.map { $0.data.filter( { $0.key == lastSelectedDate } ).values.reduce(0) { $0 + $1 } }.reduce(0) { $0 + $1 }))
                }
                .padding(.horizontal)
                .font(.title2)
            }
        }
        .listStyle(.plain)
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
        selectedAccountGroup: AccountGroup(id: 5, currency: Currency(symbol: "₽")),
        path: .constant(NavigationPath())
    )
        .environment(AlertManager(handle: {_ in }))
}
