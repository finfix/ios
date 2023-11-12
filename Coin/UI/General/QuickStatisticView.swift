//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct QuickStatisticView: View {
    
    @AppStorage("accountGroupID") var accountGroupID: Int = 0
    
            
    var body: some View {
        QuickStatisticSubView(accountGroupID: UInt32(accountGroupID))
    }
}

struct QuickStatisticSubView: View {
    
    @Query var accountGroups: [AccountGroup]
    
    init(accountGroupID: UInt32) {
        _accountGroups = Query(filter: #Predicate { $0.id == accountGroupID })
    }
    
    var accountGroup: AccountGroup {
        if accountGroups.count > 0 {
            return accountGroups.first!
        }
        return AccountGroup()
    }
    
    var body: some View {
        QuickStatisticSubSubView(accountGroup: accountGroup)
    }
}

struct QuickStatisticSubSubView: View {
    
    @Query var accounts: [Account]
    var currency: Currency
        
    var formatter: CurrencyFormatter
    
    init(accountGroup: AccountGroup) {
        self.formatter = CurrencyFormatter(currency: accountGroup.currency, maximumFractionDigits: 0)
        self.currency = accountGroup.currency ?? Currency()
        let accountGroupID = accountGroup.id
        _accounts = Query(filter: #Predicate {
            $0.accountGroup?.id == accountGroupID &&
            $0.accounting &&
            $0.visible
        })
    }
    
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
    
    func calculateStatistic(accounts: [Account], targetCurrency: Currency) -> QuickStatistic {
        let timeStart = Date()
                
        let tmp = QuickStatistic(currency: currency)
        
        for account in accounts {
                        
            let relation = targetCurrency.rate / (account.currency?.rate ?? 1)
            
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
        QuickStatisticView()
        Spacer()
    }
}
