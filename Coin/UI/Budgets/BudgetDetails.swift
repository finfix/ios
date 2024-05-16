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
    
    var daysOffsetForCalculations: Decimal {
        Decimal(account.budgetDaysOffset == 0 ? 1 : account.budgetDaysOffset)
    }
    
    var remainderForToday: Decimal {
        if today <= account.budgetDaysOffset {
            return dailyBudgetByFixedSum * Decimal(today) - account.showingRemainder
        }
        let totalBudgetByFixedSum = dailyBudgetByFixedSum * daysOffsetForCalculations
        return totalBudgetByFixedSum + dailyBudgetLeftSum * Decimal(today - Int(account.budgetDaysOffset)) - account.showingRemainder
    }
    
    var dailyBudgetByFixedSum: Decimal {
        return account.budgetFixedSum / daysOffsetForCalculations
    }
    
    var dailyBudgetLeftSum: Decimal {
        let totalBudgetByFixedSum = dailyBudgetByFixedSum * daysOffsetForCalculations
        let totalBudgetLeft = account.showingBudgetAmount - totalBudgetByFixedSum
        return totalBudgetLeft / Decimal(daysInMonth - Int(account.budgetDaysOffset))
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
                Text(currencyFormatter.string(number: today < account.budgetDaysOffset ? dailyBudgetByFixedSum : dailyBudgetLeftSum))
            }
        }
    }
}

#Preview {
    BudgetRow(account:
                    Account(
                        showingRemainder: 200,
                        showingBudgetAmount: 1000,
                        budgetFixedSum: 200,
                        budgetDaysOffset: 1
                    ),
              isDetailsOpened: true, 
              today: 16
    )
    .environment(AlertManager(handle: {_ in }))
}
