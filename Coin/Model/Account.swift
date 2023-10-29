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
    var gradualBudgetFilling: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, accountGroupID, accounting, budget, currency, iconID, name, remainder, type, visible, parentAccountID, gradualBudgetFilling
    }
    
    var childrenAccounts: [Account] = []
    var isChild: Bool = false
    
    init(
        id: UInt32 = 0,
        accountGroupID: UInt32 = 0,
        accounting: Bool = true,
        budget: Double = 0,
        currency: String = "RUB",
        iconID: UInt32 = 1,
        name: String = "",
        remainder: Double = 0,
        type: AccountType = .regular,
        visible: Bool = true,
        parentAccountID: UInt32? = nil,
        childrenAccounts: [Account] = [Account](),
        isChild: Bool = true,
        gradualBudgetFilling: Bool = false) {
        self.id = id
        self.accountGroupID = accountGroupID
        self.accounting = accounting
        self.budget = budget
        self.currency = currency
        self.iconID = iconID
        self.name = name
        self.remainder = remainder
        self.type = type
        self.visible = visible
        self.parentAccountID = parentAccountID
        self.childrenAccounts = childrenAccounts
        self.isChild = isChild
        self.gradualBudgetFilling = gradualBudgetFilling
    }
}
}

enum AccountType: String, Decodable, CaseIterable {
    case expense, earnings, debt, regular
}
