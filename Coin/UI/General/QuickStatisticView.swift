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
    
    @AppStorage("accountGroupID") var accountGroupID: Int = 0

    var accountGroup: AccountGroup {
        return AccountGroup()
    }
    
    var accounts: [Account] = []
    var currency: Currency = Currency()
    var formatter: CurrencyFormatter = CurrencyFormatter()
    
//    init() {
//        self.formatter = CurrencyFormatter(currency: accountGroup.currency, maximumFractionDigits: 0)
//    }
    
    var body: some View {
        let statistic = calculateStatistic(accounts: accounts, targetCurrency: currency)
        
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
                BudgetsList()
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
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
    
    func calculateStatistic(accounts a: [Account], targetCurrency: Currency) -> QuickStatistic {
        logger.info("Считаем статистику для шапки")
                
        let tmp = QuickStatistic(currency: currency)
        
        let accounts = Account.groupAccounts(a)
        
        for account in accounts {
            
            if account.parentAccountID != nil {
                continue
            }
                        
            let relation = targetCurrency.rate / (account.currency?.rate ?? 1)
            
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
        QuickStatisticView()
        Spacer()
    }
}
