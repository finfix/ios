//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct CreateAccountGroupReq: Codable {

    let id: UUID
    let name: String
    let currency: String
    let datetimeCreate: Date

    init(
        id: UUID,
        name: String,
        currency: String,
        datetimeCreate: Date
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.datetimeCreate = datetimeCreate
    }
}
