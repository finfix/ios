//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct GetTagsRes: Decodable {
    let id: UInt32
    let name: String
    let accountGroupID: UInt32
    let datetimeCreate: Date
}

struct GetTagsToTransactionsRes: Decodable {
    let tagID: UInt32
    let transactionID: UInt32
}

struct GetCreateTagReq: Encodable {
    let accountGroupID: UInt32
    let name: UInt32
}

struct LinkTagToTransactionReq: Encodable {
    let tagID: UInt32
    let transactionID: UInt32
}

struct UpdateTagReq: Encodable, FieldExtractable {
    let id: UInt32
    let name: String?
    
    init(
        id: UInt32,
        name: String?
    ) {
        self.id = id
        self.name = name
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
        self.name = map["name"]
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .tag, name: "id", value: String(id)))
        if let name = self.name {
            fields.append(SyncTaskValue(name: "name", value: name))
        }

        return fields
    }
}

struct DeleteTagReq: FieldExtractable {
    
    let id: UInt32
    
    init(id: UInt32) {
        self.id = id
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .tag, name: "id", value: String(self.id)))
        return fields
    }
}

struct CreateTagReq: Encodable, FieldExtractable {
    let name: String
    let accountGroupID: UInt32
    let datetimeCreate: Date
    
    init(
        name: String,
        accountGroupID: UInt32,
        datetimeCreate: Date
    ) {
        self.name = name
        self.accountGroupID = accountGroupID
        self.datetimeCreate = datetimeCreate
    }
    
    init(_ map: [String: String]) {
        self.name = map["name"]!
        self.accountGroupID = UInt32(map["accountGroupID"]!)!
        self.datetimeCreate = DateFormatters.fullTime.date(from: map["datetimeCreate"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .accountGroup, name: "accountGroupID", value: String(self.accountGroupID)))
        fields.append(SyncTaskValue(name: "name", value: String(self.name)))
        fields.append(SyncTaskValue(name: "datetimeCreate", value: DateFormatters.fullTime.string(from: self.datetimeCreate)))
        return fields
    }
}

struct CreateTagRes: Decodable {
    let id: UInt32
}
