//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct UpdateTagReq: Codable {
    let id: UUID
    let name: String?
    
    init(
        id: UUID,
        name: String?
    ) {
        self.id = id
        self.name = name
    }
}
