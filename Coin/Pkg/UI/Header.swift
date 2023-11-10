//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct Header: View {
    
    @AppStorage("accountGroupID") var accountGroupID: Int = 0
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
            
    var body: some View {
        HeaderSubView(currency: accountGroups.first {$0.id == accountGroupID}?.currency ?? "USD", accountGroupID: UInt32(accountGroupID))
    }
}

struct HeaderSubView: View {
    
    @Query var accounts: [Account]
    var currency: String
        
    var formatter: CurrencyFormatter
    
    init(currency: String, accountGroupID: UInt32) {
        self.formatter = CurrencyFormatter(currency: currency, maximumFractionDigits: 0)
        self.currency = currency
        _accounts = Query(filter: #Predicate {
            $0.accountGroupID == accountGroupID &&
            $0.accounting &&
            $0.visible
        })
    }
    
    var body: some View {
        let statistic = calculateStatistic(accounts: accounts, accountGroupCurrency: currency)
        
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
            VStack {
                Text("Бюджет")
                    .bold()
                VStack(alignment: .trailing) {
                    Text(formatter.string(number: statistic.totalBudget))
                    Text(formatter.string(number: statistic.totalBudget - statistic.totalExpense))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            Spacer()
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
    
    func calculateStatistic(accounts: [Account], accountGroupCurrency: String) -> QuickStatistic {
        let timeStart = Date()
                
        let rates = Currencies.rates
        let tmp = QuickStatistic(currency: currency)
        
        for account in accounts {
                        
            let relation = (rates[currency] ?? 1) / (rates[account.currency] ?? 1)
            
            switch account.type {
            case .expense:
                tmp.totalExpense += account.remainder * relation
                tmp.totalBudget += account.budget * relation
            case .earnings:
                continue
            default:
                tmp.totalRemainder += account.remainder * relation
            }
        }
        debugLog("Посчитали статистику для шапки", timeInterval: timeStart)
        return tmp
    }
}



#Preview {
    Group {
        Header()
        Spacer()
    }
}
