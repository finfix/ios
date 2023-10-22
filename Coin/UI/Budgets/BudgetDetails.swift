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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Бюджет на месяц: " + currencyFormat(amount: account.budget, currencyCode: account.currency))
            Text("Текущий расход: " + currencyFormat(amount: account.remainder, currencyCode: account.currency))
            Text("Остаток до конца месяца: " + currencyFormat(amount: account.budget - account.remainder, currencyCode: account.currency))
            Text("Остаток на текущий день: " + currencyFormat(amount: availableExpense, currencyCode: account.currency))
            Text("Дневной бюджет: " + currencyFormat(amount: dailyBudget, currencyCode: account.currency))
        }
    }
}

#Preview {
    BudgetDetails(account: Account(id: 1, accountGroupID: 1, accounting: true, budget: 900, currency: "rub", iconID: 2, name: "Example", remainder: 600, type: .expense, visible: true))
}
