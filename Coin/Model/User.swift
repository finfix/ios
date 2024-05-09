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
    var defaultCurrency: Currency
    
    init(
        id: UInt32 = 0,
        name: String = "",
        email: String = "",
        defaultCurrency: Currency = Currency()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.defaultCurrency = defaultCurrency
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: UserDB, currenciesMap: [String: Currency]?) {
        self.id = dbModel.id!
        self.name = dbModel.name
        self.email = dbModel.email
        self.defaultCurrency = currenciesMap?[dbModel.defaultCurrencyCode]! ?? Currency()
    }
    
    static func convertFromDBModel(_ usersDB: [UserDB], currenciesMap: [String: Currency]?) -> [User] {
        var users: [User] = []
        for userDB in usersDB {
            users.append(User(userDB, currenciesMap: currenciesMap))
        }
        return users
    }
}
