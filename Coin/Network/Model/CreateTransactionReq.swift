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
