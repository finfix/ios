//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import RealmSwift

class Transaction: Object, ObjectKeyIdentifiable, Decodable {
    @Persisted var accountFromID: Int
    @Persisted var accountToID: Int
    @Persisted var accounting: Bool
    @Persisted var amountFrom: Double
    @Persisted var amountTo: Double
    @Persisted var dateTransaction: String
    @Persisted var id: Int
    @Persisted var isExecuted: Bool
    @Persisted var note: String?
    @Persisted var typeSignatura: String
    // var tagName: [Tag]?
    // 
    // struct Tag: Decodable {
    //     var id: Int
    //     var tagID: Int
    //     var transactionID: Int
    // 
    // }
}

struct ModelError: Decodable {
    var humanTextError: String
    var developerTextError: String
    var context: String?
}

