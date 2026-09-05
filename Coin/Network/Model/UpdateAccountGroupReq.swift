//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct UpdateAccountGroupReq: Codable {
    
    let id: UUID
    let name: String?
    let currency: String?
    
    init(
        id: UUID,
        name: String?,
        currency: String?
    ) {
        self.id = id
        self.name = name
        self.currency = currency
    }
}
