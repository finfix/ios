//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct CreateTransactionReq: Encodable, FieldExtractable {
    var accountFromID: UInt32
    var accountToID: UInt32
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var note: String
    var type: String
    var isExecuted: Bool
    var tagIDs: [UInt32]
    var datetimeCreate: Date
    
    init(
        accountFromID: UInt32,
        accountToID: UInt32,
        amountFrom: Decimal,
        amountTo: Decimal,
        dateTransaction: Date,
        note: String,
        type: String,
        isExecuted: Bool,
        tagIDs: [UInt32],
        datetimeCreate: Date
    ) {
        self.accountFromID = accountFromID
        self.accountToID = accountToID
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.note = note
        self.type = type
        self.isExecuted = isExecuted
        self.tagIDs = tagIDs
        self.datetimeCreate = datetimeCreate
    }
    
    enum CodingKeys: String, CodingKey {
        case accountFromID
        case accountToID
        case amountFrom
        case amountTo
        case dateTransaction
        case note
        case type
        case isExecuted
        case tagIDs
        case datetimeCreate
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(accountFromID, forKey: .accountFromID)
        try container.encode(accountToID, forKey: .accountToID)
        try container.encode(amountFrom, forKey: .amountFrom)
        try container.encode(amountTo, forKey: .amountTo)
        try container.encode(DateFormatters.onlyDate.string(from: dateTransaction), forKey: .dateTransaction)
        try container.encode(note, forKey: .note)
        try container.encode(type, forKey: .type)
        try container.encode(isExecuted, forKey: .isExecuted)
        try container.encode(tagIDs, forKey: .tagIDs)
        try container.encode(DateFormatters.fullTime.string(from: datetimeCreate), forKey: .datetimeCreate)
    }
    
    init(_ map: [String: String]) {
        self.accountFromID = UInt32(map["accountFromID"]!)!
        self.accountToID = UInt32(map["accountToID"]!)!
        self.amountFrom = Decimal(string: map["amountFrom"]!)!
        self.amountTo = Decimal(string: map["amountTo"]!)!
        self.dateTransaction = DateFormatters.onlyDate.date(from: map["dateTransaction"]!)!
        self.note = map["note"]!
        self.type = map["type"]!
        self.isExecuted = Bool(map["isExecuted"]!)!
        self.tagIDs = []
        var i = 1
        while true {
            if let tag = map["tag\(i)"] {
                self.tagIDs.append(UInt32(tag)!)
            } else {
                break
            }
            i += 1
        }
        self.datetimeCreate = DateFormatters.fullTime.date(from: map["datetimeCreate"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .account, name: "accountFromID", value: String(self.accountFromID)))
        fields.append(SyncTaskValue(objectType: .account, name: "accountToID", value: String(self.accountToID)))
        fields.append(SyncTaskValue(name: "amountFrom", value: self.amountFrom.stringValue))
        fields.append(SyncTaskValue(name: "amountTo", value: self.amountTo.stringValue))
        fields.append(SyncTaskValue(name: "dateTransaction", value: DateFormatters.onlyDate.string(from: self.dateTransaction)))
        fields.append(SyncTaskValue(name: "note", value: String(self.note)))
        fields.append(SyncTaskValue(name: "type", value: String(self.type)))
        fields.append(SyncTaskValue(name: "isExecuted", value: String(self.isExecuted)))
        for (i, tagID) in self.tagIDs.enumerated() {
            fields.append(SyncTaskValue(objectType: .tag, name: "tag\(i)", value: String(tagID)))
        }
        fields.append(SyncTaskValue(name: "datetimeCreate", value: DateFormatters.fullTime.string(from: self.datetimeCreate)))
        return fields
    }
}

struct CreateTransactionRes: Decodable {
    var id: UInt32
}

struct UpdateTransactionReq: Encodable, FieldExtractable {
    var accountFromID: UInt32?
    var accountToID: UInt32?
    var amountFrom: Decimal?
    var amountTo: Decimal?
    var dateTransaction: Date?
    var note: String?
    var tagIDs: [UInt32]?
    var id: UInt32
    
    init(
        accountFromID: UInt32? = nil,
        accountToID: UInt32? = nil,
        amountFrom: Decimal? = nil,
        amountTo: Decimal? = nil,
        dateTransaction: Date? = nil,
        note: String? = nil,
        tagIDs: [UInt32]? = nil,
        id: UInt32
    ) {
        self.accountFromID = accountFromID
        self.accountToID = accountToID
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.note = note
        self.tagIDs = tagIDs
        self.id = id
    }
    
    enum CodingKeys: String, CodingKey {
        case accountFromID
        case accountToID
        case amountFrom
        case amountTo
        case dateTransaction
        case note
        case tagIDs
        case id
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(accountFromID, forKey: .accountFromID)
        try container.encode(accountToID, forKey: .accountToID)
        try container.encode(amountFrom, forKey: .amountFrom)
        try container.encode(amountTo, forKey: .amountTo)
        if let dateTransaction = dateTransaction {
            try container.encode(DateFormatters.onlyDate.string(from: dateTransaction), forKey: .dateTransaction)
        }
        try container.encode(tagIDs, forKey: .tagIDs)
        try container.encode(note, forKey: .note)
        try container.encode(id, forKey: .id)
    }
    
    init(_ map: [String: String]) {
        self.accountFromID = UInt32(map["accountFromID"] ?? "")
        self.accountToID = UInt32(map["accountToID"] ?? "")
        self.amountFrom = Decimal(string: map["amountFrom"] ?? "")
        self.amountTo = Decimal(string: map["amountTo"] ?? "")
        self.dateTransaction = DateFormatters.onlyDate.date(from: map["dateTransaction"] ?? "")
        self.note = map["note"]
        var i = 0
        if map["deleteAllTags"] != nil {
            self.tagIDs = []
        }
        while true {
            if let tag = map["tag\(i)"] {
                if self.tagIDs == nil {
                    self.tagIDs = []
                }
                self.tagIDs!.append(UInt32(tag)!)
            } else {
                break
            }
            i += 1
        }
        self.id = UInt32(map["id"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .transaction, name: "id", value: String(id)))
        if let accountFromID = self.accountFromID {
            fields.append(SyncTaskValue(objectType: .account, name: "accountFromID", value: String(accountFromID)))
        }
        if let accountToID = self.accountToID {
            fields.append(SyncTaskValue(objectType: .account, name: "accountToID", value: String(accountToID)))
        }
        if let amountFrom = self.amountFrom {
            fields.append(SyncTaskValue(name: "amountFrom", value: amountFrom.stringValue))
        }
        if let amountTo = self.amountTo {
            fields.append(SyncTaskValue(name: "amountTo", value: amountTo.stringValue))
        }
        if let dateTransaction = self.dateTransaction {
            fields.append(SyncTaskValue(name: "dateTransaction", value: DateFormatters.onlyDate.string(from: dateTransaction)))
        }
        if let note = self.note {
            fields.append(SyncTaskValue(name: "note", value: String(note)))
        }
        if let tagIDs = self.tagIDs {
            for (i, tagID) in tagIDs.enumerated() {
                fields.append(SyncTaskValue(objectType: .tag, name: "tag\(i)", value: String(tagID)))
            }
            if tagIDs.isEmpty {
                fields.append(SyncTaskValue(name: "deleteAllTags", value: "true"))
            }
        }
        return fields
    }
}

struct GetTransactionReq: Encodable {
    var accountID: UInt32?
    var dateFrom: Date?
    var dateTo: Date?
    var type: String?
    var offset: UInt32?
    var limit: UInt8?
}

struct GetTransactionsRes: Decodable {
    var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var accountFromID: UInt32
    var accountToID: UInt32
    var datetimeCreate: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case accounting
        case amountFrom
        case amountTo
        case dateTransaction
        case isExecuted
        case note
        case type
        case accountFromID
        case accountToID
        case datetimeCreate
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UInt32.self, forKey: .id)
        self.accounting = try container.decode(Bool.self, forKey: .accounting)
        self.amountFrom = try container.decode(Decimal.self, forKey: .amountFrom)
        self.amountTo = try container.decode(Decimal.self, forKey: .amountTo)
        self.isExecuted = try container.decode(Bool.self, forKey: .isExecuted)
        self.note = try container.decode(String.self, forKey: .note)
        self.type = try container.decode(TransactionType.self, forKey: .type)
        self.accountFromID = try container.decode(UInt32.self, forKey: .accountFromID)
        self.accountToID = try container.decode(UInt32.self, forKey: .accountToID)
        self.datetimeCreate = try container.decode(Date.self, forKey: .datetimeCreate)
        let dateTransactionString = try container.decode(String.self, forKey: .dateTransaction)
        if let dateTransaction = DateFormatters.onlyDate.date(from: dateTransactionString) {
            self.dateTransaction = dateTransaction
        } else {
            throw ErrorModel(humanTextError: "Не смогли распарсить dateTransaction")
        }
    }
}

enum DateFormatters {
    static let onlyDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    static let fullTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
}

struct DeleteTransactionReq: Encodable, FieldExtractable {
    var id: UInt32
    
    init(id: UInt32) {
        self.id = id
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .transaction, name: "id", value: String(self.id)))
        return fields
    }
}
