//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

struct ChartTab: View {
    @Environment(AlertManager.self) private var alert
    var selectedAccountGroup: AccountGroup
    @State private var vm: ChartViewModel
    @State var rawSelectedDate: Date?
    @Environment(\.calendar) var calendar
    
    let colorPerName: [String: Color] = [
        "Расходы": .red,
        "Доходы": .green
    ]
    
    init(
        selectedAccountGroup: AccountGroup,
        account: Account? = nil
    ) {
        self.formatter = CurrencyFormatter(currency: selectedAccountGroup.currency, withUnits: false)
        self.selectedAccountGroup = selectedAccountGroup
        vm = ChartViewModel(account: account)
    }
    
    var formatter: CurrencyFormatter
    
    let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.3 // Треть экрана
    
    var body: some View {
        List {
            ChartView(data: vm.data, rawSelectedDate: $rawSelectedDate, colorPerName: colorPerName)
                .frame(height: chartHeight)
            ForEach(vm.data, id: \.name) { series in
                HStack {
                    HStack {
                        Rectangle()
                            .fill(colorPerName[series.name] ?? .white)
                            .frame(width: 2, height: 15)
                        Text(series.name)
                    }
                    Spacer()
                    Text(formatter.string(number: series.data[rawSelectedDate?.startOfMonth(inUTC: true) ?? Date.now.startOfMonth(inUTC: true)] ?? 0))
                }
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
    }
}

#Preview {
    ChartTab(selectedAccountGroup: AccountGroup(id: 1))
        .environment(AlertManager(handle: {_ in }))
}
