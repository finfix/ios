//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct DeleteTransactionReq: Codable {
    var id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}
