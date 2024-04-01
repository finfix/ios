//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct AccountGroupDB {
    
    var id: UInt32
    var name: String
    var serialNumber: UInt32
    var currencyCode: String
    
    // Инициализатор из сетевой модели
    init(_ res: GetAccountGroupsRes) {
        self.id = res.id
        self.name = res.name
        self.serialNumber = res.serialNumber
        self.currencyCode = res.currency
    }
    
    static func convertFromApiModel(_ accountGroups: [GetAccountGroupsRes]) -> [AccountGroupDB] {
        var accountGroupsDB: [AccountGroupDB] = []
        for accountGroup in accountGroups {
            accountGroupsDB.append(AccountGroupDB(accountGroup))
        }
        return accountGroupsDB
    }
}

// MARK: - Persistence
extension AccountGroupDB: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let currencyCode = Column(CodingKeys.currencyCode)
        static let serialNumber = Column(CodingKeys.serialNumber)
    }
}

