//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "quick statistic")

struct QuickStatisticView: View {
    
    @State private var vm = QuickStatisticViewModel()
    @Environment(AlertManager.self) private var alert
    var selectedAccountGroup: AccountGroup
    var statistic: QuickStatistic {
        let filteredAccounts = vm.accounts.filter { $0.accountGroup == selectedAccountGroup }
        return vm.calculateStatistic(accounts: filteredAccounts, targetCurrency: selectedAccountGroup.currency)
    }
        
    var formatter: CurrencyFormatter
    
    init(
        selectedAccountGroup: AccountGroup
    ) {
        self.selectedAccountGroup = selectedAccountGroup
        formatter = CurrencyFormatter(currency: selectedAccountGroup.currency, maximumFractionDigits: 0)
    }
        
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("Расход")
                    .bold()
                Text(formatter.string(number: statistic.totalExpense))
                Spacer()
            }
            Spacer()
            VStack {
                Text("Баланс")
                    .bold()
                Text(formatter.string(number: statistic.totalRemainder))
                Spacer()
            }
            Spacer()
                
            NavigationLink {
                BudgetsList(accountGroup: selectedAccountGroup)
            } label: {
                VStack {
                    Text("Бюджет")
                        .bold()
                    VStack(alignment: .trailing) {
                        Text(formatter.string(number: statistic.totalBudget))
                        Text(formatter.string(number: statistic.periodRemainder))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
}



#Preview {
    Group {
        QuickStatisticView(selectedAccountGroup: AccountGroup())
            .environment(AlertManager(handle: {_ in }))
        Spacer()
    }
}
