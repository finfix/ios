//
//  QuickStatistic.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

struct QuickStatisticRes: Decodable {
    var totalRemainder: Double = 0
    var totalExpense: Double = 0
    var leftToSpend: Double = 0
    var totalBudget: Double = 0
}
