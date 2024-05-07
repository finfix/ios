//
//  User.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct UserDB {
    
    var id: UInt32?
    var name: String
    var email: String
    var defaultCurrencyCode: String
    
    // Инициализатор из сетевой модели
    init(_ res: GetUserRes) {
        self.id = res.id
        self.name = res.name
        self.email = res.email
        self.defaultCurrencyCode = res.defaultCurrency
    }
    
    static func compareTwoArrays(_ serverModels: [UserDB], _ localModels: [UserDB]) -> [UInt32: [String: (server: Any, local: Any)]] {
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
            if serverModel.email != localModels[i].email {
                difference["email"] = (server: serverModel.email, local: localModels[i].email)
            }
            if serverModel.defaultCurrencyCode != localModels[i].defaultCurrencyCode {
                difference["defaultCurrencyCode"] = (server: serverModel.defaultCurrencyCode, local: localModels[i].defaultCurrencyCode)
            }
            if !difference.isEmpty {
                differences[serverModel.id!] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension UserDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let email = Column(CodingKeys.email)
        static let defaultCurrencyCode = Column(CodingKeys.defaultCurrencyCode)
    }
}
