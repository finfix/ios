//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct Header: View {
    
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Query var currencies: [Currency]
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
    
    var currenciesMap: [String: Currency] {
        Dictionary(uniqueKeysWithValues: currencies.map { ($0.isoCode, $0) })
    }
    
    var currency: String {
        debugLog("Считаем валюту группы счетов ID: \(selectedAccountsGroupID)")
        return accountGroups.first{$0.id == selectedAccountsGroupID}?.currency ?? "USD"
    }
    
    var filteredAccounts: [Account] {
        debugLog("Фильтруем счета для шапки")
        return accounts.filter {
            $0.accountGroupID == selectedAccountsGroupID &&
            $0.type != .earnings &&
            ($0.budget != 0 || $0.remainder != 0) &&
            $0.childrenAccounts.isEmpty &&
            $0.accounting &&
            $0.visible
        }
    }
    
    var statistic: QuickStatistic {
        debugLog("Считаем статистику для группы счетов \(selectedAccountsGroupID)")
        let tmp = QuickStatistic(currency: currency)
        
        for account in filteredAccounts {
                        
            let relation = (currenciesMap[currency]?.rate ?? 1) / (currenciesMap[account.currency]?.rate ?? 1)
            
            switch account.type {
            case .expense:
                tmp.totalExpense += account.remainder * relation
                tmp.totalBudget += account.budget * relation
            default:
                tmp.totalRemainder += account.remainder * relation
            }
        }
        return tmp
    }
        
    var body: some View {
        HeaderSubView(statistic: statistic)
    }
}

struct HeaderSubView: View {
    
    var statistic: QuickStatistic
    
    var formatter = CurrencyFormatter(maximumFractionDigits: 0)
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("Расход")
                    .bold()
                Text(formatter.string(number: statistic.totalExpense, currency: statistic.currency))
                Spacer()
            }
            Spacer()
            VStack {
                Text("Баланс")
                    .bold()
                Text(formatter.string(number: statistic.totalRemainder, currency: statistic.currency))
                Spacer()
            }
            Spacer()
            VStack {
                Text("Бюджет")
                    .bold()
                VStack(alignment: .trailing) {
                    Text(formatter.string(number: statistic.totalBudget, currency: statistic.currency))
                    Text(formatter.string(number: statistic.totalBudget - statistic.totalExpense, currency: statistic.currency))
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
}

#Preview {
    Group {
        Header()
        Spacer()
    }
}
