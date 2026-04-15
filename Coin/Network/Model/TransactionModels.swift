//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct CreateTransactionReq: Codable {
    var id: UUID
    var accountFromID: UUID
    var accountToID: UUID
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var note: String
    var type: String
    var isExecuted: Bool
    var tagIDs: [UUID]
    var datetimeCreate: Date
    var accountingInCharts: Bool
    var accountGroupID: UUID
    
    init(
        id: UUID,
        accountFromID: UUID,
        accountToID: UUID,
        amountFrom: Decimal,
        amountTo: Decimal,
        dateTransaction: Date,
        note: String,
        type: String,
        isExecuted: Bool,
        tagIDs: [UUID],
        datetimeCreate: Date,
        accountingInCharts: Bool,
        accountGroupID: UUID
    ) {
        self.id = id
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
        self.accountingInCharts = accountingInCharts
        self.accountGroupID = accountGroupID
    }
}

struct CreateTransactionRes: Decodable {
    var id: UUID
}

struct UpdateTransactionReq: Codable {
    var accountFromID: UUID?
    var accountToID: UUID?
    var amountFrom: Decimal?
    var amountTo: Decimal?
    var dateTransaction: Date?
    var note: String?
    var tagIDs: [UUID]?
    var accountingInCharts: Bool?
    var id: UUID
    
    init(
        accountFromID: UUID? = nil,
        accountToID: UUID? = nil,
        amountFrom: Decimal? = nil,
        amountTo: Decimal? = nil,
        dateTransaction: Date? = nil,
        note: String? = nil,
        tagIDs: [UUID]? = nil,
        accountingInCharts: Bool? = nil,
        id: UUID
    ) {
        self.accountFromID = accountFromID
        self.accountToID = accountToID
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.note = note
        self.tagIDs = tagIDs
        self.accountingInCharts = accountingInCharts
        self.id = id
    }
}

struct GetTransactionReq: Codable {
    var accountID: UUID?
    var dateFrom: Date
    var dateTo: Date
    var type: String?
    var offset: UInt32?
    var limit: UInt8?
}

struct GetTransactionsRes: Decodable {
    var id: UUID
    var accountingInCharts: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var accountFromID: UUID
    var accountToID: UUID
    var datetimeCreate: Date
    var accountGroupID: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountingInCharts
        case amountFrom
        case amountTo
        case dateTransaction
        case isExecuted
        case note
        case type
        case accountFromID
        case accountToID
        case datetimeCreate
        case accountGroupID
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

struct DeleteTransactionReq: Codable {
    var id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}
