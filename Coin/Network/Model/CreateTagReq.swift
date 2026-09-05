//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct CreateTagReq: Codable {
    let id: UUID
    let name: String
    let accountGroupID: UUID
    let datetimeCreate: Date

    init(
        id: UUID,
        name: String,
        accountGroupID: UUID,
        datetimeCreate: Date
    ) {
        self.id = id
        self.name = name
        self.accountGroupID = accountGroupID
        self.datetimeCreate = datetimeCreate
    }
}
