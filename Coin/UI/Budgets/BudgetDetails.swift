//
//  BudgetDetails.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct BudgetDetails: View {
    
    var account: Account
    
    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
    let width: CGFloat = UIScreen.main.bounds.width * 0.9
    let height: CGFloat = 60
    let today = Calendar.current.component(.day, from: Date())
    
    var dailyBudget: Double {
        account.budget / Double(daysInMonth)
    }
    
    var availableExpense: Double {
        dailyBudget * Double(today) - account.remainder
    }
    
    var currencyFormatter: CurrencyFormatter
    
    init(account: Account) {
        self.currencyFormatter = CurrencyFormatter(currency: account.currency, maximumFractionDigits: 0)
        self.account = account
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Бюджет на месяц: " + currencyFormatter.string(number: account.budget))
            Text("Текущий расход: " + currencyFormatter.string(number: account.remainder))
            Text("Остаток до конца месяца: " + currencyFormatter.string(number: account.budget - account.remainder))
            Text("Остаток на текущий день: " + currencyFormatter.string(number: availableExpense))
            Text("Дневной бюджет: " + currencyFormatter.string(number: dailyBudget))
        }
    }
}

#Preview {
    BudgetDetails(account: Account(id: 1, accountGroupID: 1, accounting: true, budget: 900, currency: "rub", iconID: 2, name: "Example", remainder: 600, type: .expense, visible: true))
}
