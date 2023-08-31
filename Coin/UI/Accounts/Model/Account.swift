//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation

struct Account: Decodable, Identifiable, Hashable {
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: Double
    var currency: String
    var iconID: UInt32
    var id: UInt32
    var name: String
    var remainder: Double
    var type: String
    var visible: Bool
    var parentAccountID: UInt32?
    var childrenAccounts: [ChildAccount]?
}

struct ChildAccount: Decodable, Hashable, Identifiable {
    var accounting: Bool
    var budget: Double
    var currency: String
    var iconID: UInt32
    var id: UInt32
    var name: String
    var remainder: Double
    var visible: Bool
}

struct QuickStatisticRes: Decodable {
    var TotalRemainder: Double
    var TotalExpense: Double
    var LeftToSpend: Double
    var TotalBudget: Double
}
