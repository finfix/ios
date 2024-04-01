//
//  QuickStatistic.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

struct QuickStatistic {
    var currency: Currency
    var totalRemainder: Decimal
    var totalExpense: Decimal
    var totalBudget: Decimal
    var periodRemainder: Decimal
    
    init(
        totalRemainder: Decimal = 0,
        totalExpense: Decimal = 0,
        totalBudget: Decimal = 0,
        periodRemainder: Decimal = 0,
        currency: Currency = Currency()
    ) {
        self.totalRemainder = totalRemainder
        self.totalExpense = totalExpense
        self.totalBudget = totalBudget
        self.currency = currency
        self.periodRemainder = periodRemainder
    }
}
