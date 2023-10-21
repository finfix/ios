//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct CreateTransactionRequest: Encodable {
    var accountFromID: UInt32
    var accountToID: UInt32
    var amountFrom: Double
    var amountTo: Double
    var dateTransaction: String
    var note: String
    var type: String
    var isExecuted: Bool
}

struct UpdateTransactionReq: Encodable {
    var accountFromID: UInt32?
    var accountToID: UInt32?
    var amountFrom: Double?
    var amountTo: Double?
    var dateTransaction: Date?
    var note: String?
    var id: UInt32
//    var isExecuted: Bool
}

struct GetTransactionRequest: Encodable {
    var accountID: UInt32?
    var dateFrom: Date?
    var dateTo: Date?
    var list: UInt8?
    var type: String?
}

struct DeleteTransactionRequest: Encodable {
    var id: UInt32
}
