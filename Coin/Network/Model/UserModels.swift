//
//  UserModel.swift
//  Coin
//
//  Created by Илья on 16.11.2023.
//

import Foundation

struct UpdateUserReq: Encodable, FieldExtractable {
    
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
    
        init(_ map: [String: String]) {
            self.name = map["name"]
            self.email = map["email"]
            self.password = map["password"]
            self.oldPassword = map["oldPassword"]
            self.defaultCurrency = map["defaultCurrency"]
            self.notificationToken = map["notificationToken"]
        }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        if let name = self.name {
            fields.append(SyncTaskValue(name: "name", value: name))
        }
        if let email = self.email {
            fields.append(SyncTaskValue(name: "email", value: email))
        }
        if let password = self.password {
            fields.append(SyncTaskValue(name: "password", value: password))
        }
        if let oldPassword = self.oldPassword {
            fields.append(SyncTaskValue(name: "oldPassword", value: oldPassword))
        }
        if let defaultCurrency = self.defaultCurrency {
            fields.append(SyncTaskValue(name: "defaultCurrency", value: defaultCurrency))
        }
        if let notificationToken = self.notificationToken {
            fields.append(SyncTaskValue(name: "notificationToken", value: notificationToken))
        }
        return fields
    }
}

struct GetUserRes: Decodable {
    var id: UInt32
    var name: String
    var email: String
    var defaultCurrency: String
}
