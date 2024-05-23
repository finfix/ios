//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct GetAccountGroupsRes: Decodable {
    let id: UInt32
    let name: String
    let currency: String
    let serialNumber: UInt32
    let datetimeCreate: Date
}

struct CreateAccountGroupReq: Encodable, FieldExtractable {
    
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
    
    init(_ map: [String: String]) {
        self.name = map["name"]!
        self.currency = map["currency"]!
        self.datetimeCreate = DateFormatters.fullTime.date(from: map["datetimeCreate"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(name: "name", value: self.name))
        fields.append(SyncTaskValue(name: "currency", value: self.currency))
        fields.append(SyncTaskValue(name: "datetimeCreate", value: DateFormatters.fullTime.string(from: self.datetimeCreate)))
        return fields
    }
}

struct CreateAccountGroupRes: Decodable {
    let id: UInt32
    let serialNumber: UInt32
}

struct UpdateAccountGroupReq: Encodable, FieldExtractable {
    
    let id: UInt32
    let name: String?
    let currency: String?
    
    init(
        id: UInt32,
        name: String?,
        currency: String?
    ) {
        self.id = id
        self.name = name
        self.currency = currency
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
        self.name = map["name"]
        self.currency = map["currency"]
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .accountGroup, name: "id", value: String(id)))
        if let name = self.name {
            fields.append(SyncTaskValue(name: "name", value: name))
        }
        if let currency = self.currency {
            fields.append(SyncTaskValue(name: "currency", value: currency))
        }

        return fields
    }
}

struct DeleteAccountGroupReq: FieldExtractable {
    
    let id: UInt32
    
    init(id: UInt32) {
        self.id = id
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .accountGroup, name: "id", value: String(self.id)))
        return fields
    }
}

