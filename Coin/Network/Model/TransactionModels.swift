//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation


struct CreateTransactionRequest: Encodable {
    var accountFromID: Int
    var accountToID: Int
    var amountFrom: Double
    var amountTo: Double
    var dateTransaction: String
    var note: String
    var type: String
    var isExecuted: Bool
}

struct UpdateTransactionRequest: Encodable {
    var accountFromID: Int
    var accountToID: Int
    var amountFrom: Double
    var amountTo: Double
    var dateTransaction: String
    var note: String
    var id: Int
    var isExecuted: Bool
}
