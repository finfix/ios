//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct CreateTransactionReq: Encodable {
    var accountFromID: UInt32
    var accountToID: UInt32
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: String
    var note: String
    var type: String
    var isExecuted: Bool
}

struct CreateTransactionRes: Decodable {
    var id: UInt32
}

struct UpdateTransactionReq: Encodable {
    var accountFromID: UInt32?
    var accountToID: UInt32?
    var amountFrom: Decimal?
    var amountTo: Decimal?
    var dateTransaction: Date?
    var note: String?
    var id: UInt32
//    var isExecuted: Bool
}

struct GetTransactionReq: Encodable {
    var accountID: UInt32?
    var dateFrom: Date?
    var dateTo: Date?
    var type: String?
    var offset: UInt32?
    var limit: UInt8?
}

struct GetTransactionsRes: Decodable {
    var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var accountFromID: UInt32
    var accountToID: UInt32
}

struct DeleteTransactionReq: Encodable {
    var id: UInt32
}
