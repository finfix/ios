//
//  UserModel.swift
//  Coin
//
//  Created by Илья on 16.11.2023.
//

import Foundation

struct UpdateUserReq: Codable {
    
    var name: String?
    var email: String?
    var password: String?
    var oldPassword: String?
    var defaultCurrency: String?
    var notificationToken: String?
    
    init(
        name: String? = nil,
        email: String? = nil,
        password: String? = nil,
        oldPassword: String? = nil,
        defaultCurrency: String? = nil,
        notificationToken: String? = nil
    ) {
        self.name = name
        self.email = email
        self.password = password
        self.oldPassword = oldPassword
        self.defaultCurrency = defaultCurrency
        self.notificationToken = notificationToken
    }
}

struct GetUserRes: Decodable {
    var id: UUID
    var name: String
    var email: String
    var defaultCurrency: String
}
