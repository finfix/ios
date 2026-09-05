//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct DeleteTagReq: Codable {
    
    let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}
