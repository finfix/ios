//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import RealmSwift

class Transaction: Object, ObjectKeyIdentifiable, Decodable {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var accountFromID: Int
    @Persisted var accountToID: Int
    @Persisted var accounting: Bool
    @Persisted var amountFrom: Double
    @Persisted var amountTo: Double
    @Persisted var dateTransaction: String
    @Persisted var isExecuted: Bool
    @Persisted var note: String?
    @Persisted var typeSignatura: String
}

