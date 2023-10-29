//
//  QuickStatistic.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

class QuickStatistic: Decodable {
    var currency: String
    var totalRemainder: Double
    var totalExpense: Double
    var totalBudget: Double
    
    init(currency: String = "USD", totalRemainder: Double = 0, totalExpense: Double = 0, totalBudget: Double = 0) {
        self.currency = currency
        self.totalRemainder = totalRemainder
        self.totalExpense = totalExpense
        self.totalBudget = totalBudget
    }
}
