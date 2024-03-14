//
//  User.swift
//  Coin
//
//  Created by Илья on 30.10.2023.
//

import Foundation

struct User {
    
    var id: UInt32
    var name: String
    var email: String
    var timeCreate: Date
    
    init(
        id: UInt32 = 0,
        name: String = "",
        email: String = "",
        timeCreate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.timeCreate = timeCreate
    }
    
    init(_ res: GetUserRes, currenciesMap: [String: Currency]) {
        self.id = res.id
        self.name = res.name
        self.email = res.email
        self.timeCreate = Date()
    }
}
