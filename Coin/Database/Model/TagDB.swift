//
//  TagDB.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation
import GRDB

struct TagDB {
    
    var id: UInt32?
    var name: String
    var accountGroupID: UInt32
    var datetimeCreate: Date
    
    init(
        id: UInt32?,
        name: String,
        accountGroupID: UInt32,
        datetimeCreate: Date
    ) {
        self.id = id
        self.name = name
        self.accountGroupID = accountGroupID
        self.datetimeCreate = datetimeCreate
    }
    
    // Инициализатор из бизнес модели
    init(_ model: Tag) {
        self.id = model.id
        if self.id == 0 {
            self.id = nil
        }
        self.name = model.name
        self.accountGroupID = model.accountGroup.id
        self.datetimeCreate = model.datetimeCreate
    }
    
    // Инициализатор из сетевой модели
    init(_ res: GetTagsRes) {
        self.id = res.id
        self.name = res.name
        self.accountGroupID = res.accountGroupID
        self.datetimeCreate = res.datetimeCreate
    }
    
    static func convertFromApiModel(_ icons: [GetTagsRes]) -> [TagDB] {
        var iconsDB: [TagDB] = []
        for icon in icons {
            iconsDB.append(TagDB(icon))
        }
        return iconsDB
    }
    
    static func compareTwoArrays(_ serverModels: [TagDB], _ localModels: [TagDB]) -> [UInt32: [String: (server: Any, local: Any)]] {
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
            if serverModel.accountGroupID != localModels[i].accountGroupID {
                difference["accountGroupID"] = (server: serverModel.accountGroupID, local: localModels[i].accountGroupID)
            }
//            if serverModel.datetimeCreate != localModels[i].datetimeCreate {
//                difference["datetimeCreate"] = (server: serverModel.datetimeCreate, local: localModels[i].datetimeCreate)
//            }
            if !difference.isEmpty {
                differences[serverModel.id!] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension TagDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let accountGroupID = Column(CodingKeys.accountGroupID)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
    }
}

