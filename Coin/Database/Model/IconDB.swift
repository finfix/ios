//
//  IconDB.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation
import GRDB

struct IconDB {
    
    var id: UInt32
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
}

// MARK: - Persistence
extension IconDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let url = Column(CodingKeys.url)
    }
}
