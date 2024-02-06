//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "quick statistic")

struct QuickStatisticView: View {
    
    @AppStorage("accountGroupID") var accountGroupID: Int = 0
    
            
    var body: some View {
        QuickStatisticSubView(accountGroupID: UInt32(accountGroupID))
    }
}

struct QuickStatisticSubView: View {
    
    @Query(sort: [
        SortDescriptor(\AccountGroup.serialNumber)
    ]) var accountGroups: [AccountGroup]
    
    init(accountGroupID: UInt32) {
        _accountGroups = Query(filter: #Predicate { $0.id == accountGroupID })
    }
    
    var accountGroup: AccountGroup {
        if let accountGroup = accountGroups.first {
            return accountGroup
        }
        return AccountGroup()
    }
    
    var body: some View {
        QuickStatisticSubSubView(accountGroup: accountGroup)
    }
}

struct QuickStatisticSubSubView: View {
    
    @Query(sort: [
        SortDescriptor(\Account.serialNumber)
    ]) var accounts: [Account]
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
                
            NavigationLink {
                BudgetsList()
            } label: {
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
            }
            .buttonStyle(.plain)

           
            
            Spacer()
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
    
    func calculateStatistic(accounts: [Account], targetCurrency: Currency) -> QuickStatistic {
        logger.info("Считаем статистику для шапки")
                
        let tmp = QuickStatistic(currency: currency)
        
        for account in accounts {
                        
            let relation = targetCurrency.rate / (account.currency?.rate ?? 1)
            
            switch account.type {
            case .expense:
                tmp.totalExpense += account.remainder * relation
                tmp.totalBudget += account.budgetAmount * relation
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
    .modelContainer(previewContainer)
}
