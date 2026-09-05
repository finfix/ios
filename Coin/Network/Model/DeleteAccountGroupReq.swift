//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct DeleteAccountGroupReq: Codable {
    
    let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}
