//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation

struct AccountGroup: Identifiable, Hashable {
    var id: UUID
    var name: String
    var serialNumber: UInt32
    var currency: Currency
    var datetimeCreate: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        serialNumber: UInt32 = 0,
        currency: Currency = Currency(),
        datetimeCreate: Date = Date.now
    ) {
        self.id = id
        self.name = name
        self.serialNumber = serialNumber
        self.currency = currency
        self.datetimeCreate = datetimeCreate
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: AccountGroupDB, currenciesMap: [String: Currency]?) {
        self.id = dbModel.id!
        self.name = dbModel.name
        self.serialNumber = dbModel.serialNumber
        self.currency = currenciesMap?[dbModel.currencyCode]! ?? Currency()
        self.datetimeCreate = dbModel.datetimeCreate
    }
    
    static func convertFromDBModel(_ accountGroupsDB: [AccountGroupDB], currenciesMap: [String: Currency]?) -> [AccountGroup] {
        var accountGroups: [AccountGroup] = []
        for accountGroupDB in accountGroupsDB {
            accountGroups.append(AccountGroup(accountGroupDB, currenciesMap: currenciesMap))
        }
        return accountGroups
    }
    
    static func convertToMap(_ accountGroups: [AccountGroup]) -> [UUID: AccountGroup] {
        return Dictionary(uniqueKeysWithValues: accountGroups.map{ ($0.id, $0) })
    }
}
