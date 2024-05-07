//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation

struct AccountGroup: Identifiable {
    var id: UInt32
    var name: String
    var serialNumber: UInt32
    var currency: Currency
    
    init(
        id: UInt32 = 0,
        name: String = "",
        serialNumber: UInt32 = 0,
        currency: Currency = Currency()
    ) {
        self.id = id
        self.name = name
        self.serialNumber = serialNumber
        self.currency = currency
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: AccountGroupDB, currenciesMap: [String: Currency]?) {
        self.id = dbModel.id!
        self.name = dbModel.name
        self.serialNumber = dbModel.serialNumber
        self.currency = currenciesMap?[dbModel.currencyCode]! ?? Currency()
    }
    
    static func convertFromDBModel(_ accountGroupsDB: [AccountGroupDB], currenciesMap: [String: Currency]?) -> [AccountGroup] {
        var accountGroups: [AccountGroup] = []
        for accountGroupDB in accountGroupsDB {
            accountGroups.append(AccountGroup(accountGroupDB, currenciesMap: currenciesMap))
        }
        return accountGroups
    }
    
    static func convertToMap(_ accountGroups: [AccountGroup]) -> [UInt32: AccountGroup] {
        return Dictionary(uniqueKeysWithValues: accountGroups.map{ ($0.id, $0) })
    }
}

extension AccountGroup: Hashable {
    static func == (lhs: AccountGroup, rhs: AccountGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
