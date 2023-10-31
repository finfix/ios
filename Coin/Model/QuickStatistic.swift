//
//  QuickStatistic.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

class QuickStatistic: Decodable {
    var currency: String
    var totalRemainder: Decimal
    var totalExpense: Decimal
    var totalBudget: Decimal
    
    init(currency: String = "USD", totalRemainder: Decimal = 0, totalExpense: Decimal = 0, totalBudget: Decimal = 0) {
        self.currency = currency
        self.totalRemainder = totalRemainder
        self.totalExpense = totalExpense
        self.totalBudget = totalBudget
    }
}
