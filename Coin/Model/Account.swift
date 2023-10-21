//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation

struct Account: Decodable, Identifiable, Hashable {
    var id: UInt32
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: Double
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Double
    var type: AccountType
    var visible: Bool
    var parentAccountID: UInt32?
    var childrenAccounts: [Account]?
    var currencySymbol: String
}

enum AccountType: String, Decodable {
    case expense, earnings, debt, investment, credit, regular
}
