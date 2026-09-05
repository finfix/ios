//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

struct DeleteAccountReq: Codable {
    var id: UUID
    
    init(
        id: UUID
    ) {
        self.id = id
    }
}
