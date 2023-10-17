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
    var type: String
    var tagName: [Tag]?

    struct Tag: Decodable {
        var id: UInt32
        var tagID: UInt32
        var transactionID: UInt32
    }
}

struct ModelError: Decodable {
    var humanTextError: String
    var developerTextError: String
    var context: String?
}

