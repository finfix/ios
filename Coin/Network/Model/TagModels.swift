//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct GetTagsRes: Decodable {
    let id: UUID
    let name: String
    let accountGroupID: UUID
    let datetimeCreate: Date
}

struct GetTagsToTransactionsRes: Decodable {
    let tagID: UUID
    let transactionID: UUID
}

struct GetCreateTagReq: Codable {
    let accountGroupID: UUID
    let name: UInt32
}

struct LinkTagToTransactionReq: Codable {
    let tagID: UUID
    let transactionID: UUID
}

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

struct DeleteTagReq: Codable {
    
    let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}

struct CreateTagReq: Codable {
    let name: String
    let accountGroupID: UUID
    let datetimeCreate: Date
    
    init(
        name: String,
        accountGroupID: UUID,
        datetimeCreate: Date
    ) {
        self.name = name
        self.accountGroupID = accountGroupID
        self.datetimeCreate = datetimeCreate
    }
}

struct CreateTagRes: Decodable {
    let id: UUID
}
