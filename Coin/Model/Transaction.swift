//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import SwiftData

@Model 
class Transaction {
    
    @Attribute(.unique) var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var isSaved: Bool
    
    var accountFrom: Account?
    var accountTo: Account?
    
    init(
        id: UInt32 = 0,
        accounting: Bool = true,
        amountFrom: Decimal = 0,
        amountTo: Decimal = 0,
        dateTransaction: Date = Date(),
        isExecuted: Bool = true,
        note: String = "",
        type: TransactionType = .consumption,
        isSaved: Bool = false,
        accountFrom: Account? = nil,
        accountTo: Account? = nil
    ) {
        self.accounting = accounting
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.id = id
        self.isExecuted = isExecuted
        self.note = note
        self.type = type
        self.isSaved = isSaved
        self.accountFrom = accountFrom
        self.accountTo = accountTo
    }
    
    init(_ res: GetTransactionsRes, accountsMap: [UInt32: Account]) {
        self.accounting = res.accounting
        self.amountFrom = res.amountFrom
        self.amountTo = res.amountTo
        self.dateTransaction = res.dateTransaction
        self.id = res.id
        self.isExecuted = res.isExecuted
        self.note = res.note
        self.type = res.type
        self.isSaved = true
        self.accountFrom = accountsMap[res.accountFromID]
        self.accountTo = accountsMap[res.accountToID]
    }
}

enum TransactionType: String, Codable {
    case consumption, income, transfer, balancing
}
