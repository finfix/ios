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
    
    private enum CodingKeys: String, CodingKey {
        case id, accountGroupID, accounting, budget, currency, iconID, name, remainder, type, visible, parentAccountID
    }
    
    var childrenAccounts: [Account] = []
    var isChild: Bool = false
}

enum AccountType: String, Decodable, CaseIterable {
    case expense, earnings, debt, regular
}
