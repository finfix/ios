//
//  Tag.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct Tag: Identifiable {
    
    var id: UInt32
    var name: String
    var accountGroup: AccountGroup
    var datetimeCreate: Date
    
    init(
        id: UInt32 = 0,
        name: String = "",
        accountGroup: AccountGroup = AccountGroup(),
        datetimeCreate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.accountGroup = accountGroup
        self.datetimeCreate = datetimeCreate
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: TagDB, accountGroupsMap: [UInt32: AccountGroup]?) {
        self.id = dbModel.id!
        self.name = dbModel.name
        self.datetimeCreate = dbModel.datetimeCreate
        self.accountGroup = accountGroupsMap?[dbModel.accountGroupID] ?? AccountGroup()
    }
    
    static func convertFromDBModel(_ tagsDB: [TagDB], accountGroupsMap: [UInt32: AccountGroup]?) -> [Tag] {
        var tags: [Tag] = []
        for tagDB in tagsDB {
            tags.append(Tag(tagDB, accountGroupsMap: accountGroupsMap))
        }
        return tags
    }
    
    static func convertToMap(_ tags: [Tag]) -> [UInt32: Tag] {
        return Dictionary(uniqueKeysWithValues: tags.map{ ($0.id, $0) })
    }
}

extension Tag: Hashable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
