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
    
    var dailyBudget: Decimal {
        account.showingBudget / Decimal(daysInMonth)
    }
    
    var availableExpense: Decimal {
        dailyBudget * Decimal(today) - account.showingRemainder
    }
    
    var currencyFormatter: CurrencyFormatter
    
    init(account: Account) {
        self.currencyFormatter = CurrencyFormatter(currency: account.currency, maximumFractionDigits: 0)
        self.account = account
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Бюджет на месяц: ")
                Text("Текущий расход: ")
                Text("Остаток до конца месяца: ")
                Text("Остаток на текущий день: ")
                Text("Дневной бюджет: ")
            }
            VStack(alignment: .trailing) {
                Text(currencyFormatter.string(number: account.showingBudget))
                Text(currencyFormatter.string(number: account.showingRemainder))
                Text(currencyFormatter.string(number: account.showingBudget - account.showingRemainder))
                Text(currencyFormatter.string(number: availableExpense))
                Text(currencyFormatter.string(number: dailyBudget))
            }
        }
    }
}

#Preview {
    BudgetDetails(account: Account())
}
