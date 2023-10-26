//
//  QuickStatistic.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

struct QuickStatistic: Decodable {
    var currency: String = ""
    var totalRemainder: Double = 0
    var totalExpense: Double = 0
    var totalBudget: Double = 0
}
