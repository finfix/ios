//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

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
