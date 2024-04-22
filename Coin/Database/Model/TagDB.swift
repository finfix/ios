//
//  TagDB.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation
import GRDB

struct TagDB {
    
    var id: UInt32
    var name: String
    var accountGroupID: UInt32
    var datetimeCreate: Date
    
    init(
        id: UInt32,
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

