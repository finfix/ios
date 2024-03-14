//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation

struct AccountGroup: Identifiable, Hashable {
    
    static func == (lhs: AccountGroup, rhs: AccountGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id: UInt32
    var name: String
    var currency: Currency?
    var serialNumber: UInt32
    var accounts: [Account]
        
    init(
        id: UInt32 = 0,
        name: String = "",
        serialNumber: UInt32 = 0,
        currency: Currency? = nil,
        accounts: [Account] = []
    ) {
        self.id = id
        self.name = name
        self.serialNumber = serialNumber
        self.currency = currency
        self.accounts = accounts
    }
    
    init(_ res: GetAccountGroupsRes, currenciesMap: [String: Currency]) {
        self.id = res.id
        self.name = res.name
        self.serialNumber = res.serialNumber
        self.accounts = []
        self.currency = currenciesMap[res.currency]
    }
}
