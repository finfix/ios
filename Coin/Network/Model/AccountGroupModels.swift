//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct GetAccountGroupsRes: Decodable {
    let id: UUID
    let name: String
    let currency: String
    let serialNumber: UInt32
    let datetimeCreate: Date
}

struct CreateAccountGroupReq: Codable {
    
    let name: String
    let currency: String
    let datetimeCreate: Date
    
    init(
        name: String,
        currency: String,
        datetimeCreate: Date
    ) {
        self.name = name
        self.currency = currency
        self.datetimeCreate = datetimeCreate
    }
}

struct CreateAccountGroupRes: Decodable {
    let id: UUID
    let serialNumber: UInt32
}

struct UpdateAccountGroupReq: Codable {
    
    let id: UUID
    let name: String?
    let currency: String?
    
    init(
        id: UUID,
        name: String?,
        currency: String?
    ) {
        self.id = id
        self.name = name
        self.currency = currency
    }
}

struct DeleteAccountGroupReq: Codable {
    
    let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}

