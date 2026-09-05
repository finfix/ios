//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct LinkTagToTransactionReq: Codable {
    let tagID: UUID
    let transactionID: UUID
}
