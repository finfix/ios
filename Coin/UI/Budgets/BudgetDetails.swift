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
            Text("Остаток: \(String(format: "%.0f", availableExpense)) \(account.currencySymbol)")
            Text("Дневной бюджет: \(String(format: "%.0f", dailyBudget)) \(account.currencySymbol)")
            Text("Бюджет на месяц: \(String(format: "%.0f", account.budget)) \(account.currencySymbol)")
            Text("Текущий расход: \(String(format: "%.0f", account.remainder)) \(account.currencySymbol)")
        }
    }
}

#Preview {
    BudgetDetails(account: Account(id: 1, accountGroupID: 1, accounting: true, budget: 900, currency: "rub", iconID: 2, name: "Example", remainder: 600, type: .expense, visible: true, currencySymbol: "$"))
}
