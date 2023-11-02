//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation
import SwiftData

@Model class Account: Decodable, Identifiable {
    
    @Attribute(.unique) var id: UInt32
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: Decimal
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UInt32?
    var gradualBudgetFilling: Bool
    
    var childrenAccounts: [Account] = []
    var isChild: Bool = false
    
    init(
        id: UInt32 = 0,
        accountGroupID: UInt32 = 0,
        accounting: Bool = true,
        budget: Decimal = 0,
        currency: String = "RUB",
        iconID: UInt32 = 1,
        name: String = "",
        remainder: Decimal = 0,
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

    private enum CodingKeys: String, CodingKey {
        case id, accountGroupID, accounting, budget, currency, iconID, name, remainder, type, visible, parentAccountID, gradualBudgetFilling
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UInt32.self, forKey: .id)
        accountGroupID = try container.decode(UInt32.self, forKey: .accountGroupID)
        accounting = try container.decode(Bool.self, forKey: .accounting)
        budget = try container.decode(Decimal.self, forKey: .budget)
        currency = try container.decode(String.self, forKey: .currency)
        iconID = try container.decode(UInt32.self, forKey: .iconID)
        name = try container.decode(String.self, forKey: .name)
        remainder = try container.decode(Decimal.self, forKey: .remainder)
        type = try container.decode(AccountType.self, forKey: .type)
        visible = try container.decode(Bool.self, forKey: .visible)
        parentAccountID = try container.decode(UInt32?.self, forKey: .parentAccountID)
        gradualBudgetFilling = try container.decode(Bool.self, forKey: .gradualBudgetFilling)
    }
}

func groupAccounts(accounts: [Account], currencies: [Currency]) -> [Account] {
    
    var ratesMap: [String: Decimal] {
        Dictionary(uniqueKeysWithValues: currencies.map { ($0.isoCode, $0.rate ) })
    }
    
    for (i, account) in accounts.enumerated() {
        if let parentAccountID = account.parentAccountID {
            let parentAccountIndex = accounts.firstIndex { $0.id == parentAccountID }
            let parentAccount = accounts[parentAccountIndex!]
            
            if account.visible {
                accounts[parentAccountIndex!].childrenAccounts.append(account)
                if account.accounting {
                    let relation = (ratesMap[parentAccount.currency] ?? 1) / (ratesMap[account.currency] ?? 1)
                    accounts[parentAccountIndex!].budget += account.budget * relation
                    accounts[parentAccountIndex!].remainder += account.remainder * relation
                }
            }
            accounts[i].isChild = true
        }
    }
    return accounts
}


extension Account: Hashable {
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum AccountType: String, Codable, CaseIterable {
    case expense, earnings, debt, regular
}
