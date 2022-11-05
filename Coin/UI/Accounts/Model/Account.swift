//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation
import RealmSwift

class Account: Object, ObjectKeyIdentifiable, Decodable {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var accountGroupID: Int
    @Persisted var accounting: Bool
    @Persisted var budget: Double?
    @Persisted var currencySignatura: String
    @Persisted var iconID: Int
    @Persisted var name: String
    @Persisted var remainder: Double
    @Persisted var typeSignatura: String
    @Persisted var userID: Int
    @Persisted var visible: Bool
}
