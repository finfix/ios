//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct CreateTransactionReq: Encodable {
    var accountFromID: UInt32
    var accountToID: UInt32
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var note: String
    var type: String
    var isExecuted: Bool
    
    enum CodingKeys: String, CodingKey {
        case accountFromID
        case accountToID
        case amountFrom
        case amountTo
        case dateTransaction
        case note
        case type
        case isExecuted
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
    }
}

struct CreateTransactionRes: Decodable {
    var id: UInt32
}

struct UpdateTransactionReq: Encodable {
    var accountFromID: UInt32?
    var accountToID: UInt32?
    var amountFrom: Decimal?
    var amountTo: Decimal?
    var dateTransaction: Date?
    var note: String?
    var id: UInt32
    
    enum CodingKeys: String, CodingKey {
        case accountFromID
        case accountToID
        case amountFrom
        case amountTo
        case dateTransaction
        case note
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
        try container.encode(note, forKey: .note)
        try container.encode(id, forKey: .id)
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

struct DeleteTransactionReq: Encodable {
    var id: UInt32
}
