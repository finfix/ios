//
//  IconDB.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation
import GRDB

struct IconDB {
    
    var id: UInt32?
    var name: String
    var url: String
    
    init(
        id: UInt32,
        name: String,
        url: String
    ) {
        self.id = id
        self.name = name
        self.url = url
    }
    
    // Инициализатор из сетевой модели
    init(_ res: GetIconsRes) {
        self.id = res.id
        self.name = res.name
        self.url = res.url
    }
    
    static func convertFromApiModel(_ icons: [GetIconsRes]) -> [IconDB] {
        var iconsDB: [IconDB] = []
        for icon in icons {
            iconsDB.append(IconDB(icon))
        }
        return iconsDB
    }
    
    static func compareTwoArrays(_ serverModels: [IconDB], _ localModels: [IconDB]) -> [UInt32: [String: (server: Any, local: Any)]] {
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
//            if serverModel.url != localModels[i].url {
//                difference["url"] = (server: serverModel.url, local: localModels[i].url)
//            }
            if !difference.isEmpty {
                differences[serverModel.id!] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension IconDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let url = Column(CodingKeys.url)
    }
}
