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
    
    private let service = Service.shared
        
    var selectedAccountGroup: AccountGroup
    @State var accounts: [Account] = []
    @State var statistic = QuickStatistic()
        
    var formatter: CurrencyFormatter {
        CurrencyFormatter(currency: selectedAccountGroup.currency, maximumFractionDigits: 0)
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
            load()
        }
        .onChange(of: selectedAccountGroup) {
            load()
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
    
    func load() {
        do {
            accounts = try service.getAccounts(accountGroup: selectedAccountGroup, accounting: true)
            statistic = calculateStatistic(accounts: accounts, targetCurrency: selectedAccountGroup.currency)
        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func calculateStatistic(accounts a: [Account], targetCurrency: Currency) -> QuickStatistic {
        var tmp = QuickStatistic(currency: targetCurrency)
        
        let accounts = Account.groupAccounts(a)
        
        for account in accounts {
            
            if account.parentAccountID != nil {
                continue
            }
                        
            let relation = targetCurrency.rate / (account.currency.rate)
            
            switch account.type {
            case .expense:
                tmp.totalExpense += account.remainder * relation
                tmp.totalBudget += account.budgetAmount * relation
                if account.budgetAmount != 0 && account.budgetAmount > account.remainder {
                    tmp.periodRemainder += (account.budgetAmount - account.remainder) * relation
                }
            case .earnings:
                continue
            default:
                tmp.totalRemainder += account.remainder * relation
            }
        }
        return tmp
    }
}



#Preview {
    Group {
        QuickStatisticView(selectedAccountGroup: AccountGroup())
        Spacer()
    }
}
