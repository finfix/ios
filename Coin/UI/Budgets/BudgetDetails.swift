//
//  BudgetDetails.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct BudgetDetails: View {
    
    var account: Account
    var today: Int
    private var currencyFormatter: CurrencyFormatter
    
    init(account: Account, today: Int) {
        self.currencyFormatter = CurrencyFormatter(currency: account.currency, maximumFractionDigits: 0)
        self.account = account
        self.today = today
    }
    
    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
    let height: CGFloat = 60
    
    var remainderForToday: Decimal {
        if today <= account.budgetDaysOffset {
            return dailyBudgetByFixedSum * Decimal(today) - account.showingRemainder
        }
        let totalBudgetByFixedSum = dailyBudgetByFixedSum * Decimal(account.budgetDaysOffset)
        return totalBudgetByFixedSum + dailyBudgetLeftSum * Decimal(today - Int(account.budgetDaysOffset)) - account.showingRemainder
    }
    
    var dailyBudgetByFixedSum: Decimal {
        let daysOffset = Decimal(account.budgetDaysOffset == 0 ? 1 : account.budgetDaysOffset)
        return account.budgetFixedSum / daysOffset
    }
    
    var dailyBudgetLeftSum: Decimal {
        return (account.showingBudgetAmount - dailyBudgetByFixedSum * Decimal(account.budgetDaysOffset)) / Decimal(daysInMonth - Int(account.budgetDaysOffset))
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
                Text(currencyFormatter.string(number: account.showingBudgetAmount))
                Text(currencyFormatter.string(number: account.showingRemainder))
                Text(currencyFormatter.string(number: account.showingBudgetAmount - account.showingRemainder))
                Text(currencyFormatter.string(number: remainderForToday))
                Text(currencyFormatter.string(number: today <= account.budgetDaysOffset ? dailyBudgetByFixedSum : dailyBudgetLeftSum))
            }
        }
    }
}

#Preview {
    BudgetRow(account:
                    Account(
                        showingRemainder: 4470000,
                        showingBudgetAmount: 7200000,
                        budgetFixedSum: 4420000,
                        budgetDaysOffset: 16
                    ),
              isDetailsOpened: true, 
              today: 16
    )
    .environment(AlertManager(handle: {_ in }))
}
