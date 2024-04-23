//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct GetTagsRes: Decodable {
    let id: UInt32
    let name: String
    let accountGroupID: UInt32
    let datetimeCreate: Date
}

struct GetTagsToTransactionsRes: Decodable {
    let tagID: UInt32
    let transactionID: UInt32
}

struct GetCreateTagReq: Encodable {
    let accountGroupID: UInt32
    let name: UInt32
}

struct LinkTagToTransactionReq: Encodable {
    let tagID: UInt32
    let transactionID: UInt32
}

struct UpdateTagReq: Encodable {
    let id: UInt32
    let name: String?
}

struct DeleteTagReq {
    let id: UInt32
}

struct CreateTagReq: Encodable {
    let name: String
    let accountGroupID: UInt32
    let datetimeCreate: Date
}

struct CreateTagRes: Decodable {
    let id: UInt32
}
