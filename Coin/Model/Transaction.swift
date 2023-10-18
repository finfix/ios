//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation


struct Transaction: Decodable, Identifiable {
    var accountFromID: UInt32
    var accountToID: UInt32
    var accounting: Bool
    var amountFrom: Double
    var amountTo: Double
    var dateTransaction: Date
    var id: UInt32
    var isExecuted: Bool
    var note: String
    var type: TransactionType
}

enum TransactionType: String, Decodable {
    case consumption, income, transfer, balancing
}

struct ModelError: Decodable {
    var humanTextError: String
    var developerTextError: String
    var context: String?
}

