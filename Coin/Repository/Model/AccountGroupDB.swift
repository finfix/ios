//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct AccountGroupDB {
    
    var id: UInt32?
    var name: String
    var serialNumber: UInt32
    var currencyCode: String
    var datetimeCreate: Date
    
    // Инициализатор из сетевой модели
    init(_ res: GetAccountGroupsRes) {
        self.id = res.id
        self.name = res.name
        self.serialNumber = res.serialNumber
        self.currencyCode = res.currency
        self.datetimeCreate = res.datetimeCreate
    }
    
    // Инициализатор из бизнес модели
    init(_ model: AccountGroup) {
        self.id = model.id
        if self.id == 0 {
            self.id = nil
        }
        self.name = model.name
        self.serialNumber = model.serialNumber
        self.currencyCode = model.currency.code
        self.datetimeCreate = model.datetimeCreate
    }
    
    static func convertFromApiModel(_ accountGroups: [GetAccountGroupsRes]) -> [AccountGroupDB] {
        var accountGroupsDB: [AccountGroupDB] = []
        for accountGroup in accountGroups {
            accountGroupsDB.append(AccountGroupDB(accountGroup))
        }
        return accountGroupsDB
    }
    
    static func compareTwoArrays(_ serverModels: [AccountGroupDB], _ localModels: [AccountGroupDB]) -> [UInt32: [String: (server: Any, local: Any)]] {
        let serverModels = serverModels.sorted { $0.id! < $1.id! }
        let localModels = localModels.sorted { $0.id! < $1.id! }
        
        var differences: [UInt32: [String: (server: Any, local: Any)]] = [:]
        
        guard serverModels.count == localModels.count else {
            var difference: [String: (server: Any, local: Any)] = ["count": (server: serverModels.count, local: localModels.count)]
            differences[0] = difference
            return differences
        }
        
        for (i, serverModel) in serverModels.enumerated() {
            var difference: [String: (server: Any, local: Any)] = [:]
            if serverModel.id! != localModels[i].id {
                difference["id"] = (server: serverModel.id!, local: localModels[i].id!)
            }
            if serverModel.name != localModels[i].name {
                difference["name"] = (server: serverModel.name, local: localModels[i].name)
            }
            if serverModel.serialNumber != localModels[i].serialNumber {
                difference["serialNumber"] = (server: serverModel.serialNumber, local: localModels[i].serialNumber)
            }
            if serverModel.currencyCode != localModels[i].currencyCode {
                difference["currencyCode"] = (server: serverModel.currencyCode, local: localModels[i].currencyCode)
            }
            if serverModel.datetimeCreate != localModels[i].datetimeCreate {
                difference["datetimeCreate"] = (server: serverModel.datetimeCreate, local: localModels[i].datetimeCreate)
            }
            if !difference.isEmpty {
                differences[serverModel.id!] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension AccountGroupDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let currencyCode = Column(CodingKeys.currencyCode)
        static let serialNumber = Column(CodingKeys.serialNumber)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
    }
}

