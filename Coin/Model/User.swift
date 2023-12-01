//
//  User.swift
//  Coin
//
//  Created by Илья on 30.10.2023.
//

import Foundation
import SwiftData

@Model class User {
    
    @Attribute(.unique) var id: UInt32
    var name: String
    var email: String
    var timeCreate: Date
    var currency: Currency?
    
    init(
        id: UInt32 = 0,
        name: String = "",
        email: String = "",
        timeCreate: Date = Date(),
        currency: Currency? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.timeCreate = timeCreate
        self.currency = currency
    }
    
    init(_ res: GetUserRes, currenciesMap: [String: Currency]) {
        self.id = res.id
        self.name = res.name
        self.email = res.email
        self.timeCreate = Date()
        self.currency = currenciesMap[res.defaultCurrency]
    }
}
