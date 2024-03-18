//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import SwiftUI

class Transaction: Identifiable, Hashable {
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var timeCreate: Date
    
    var accountFrom: Account
    var accountTo: Account
    
    init(
        id: UInt32 = 0,
        accounting: Bool = true,
        amountFrom: Decimal = 0,
        amountTo: Decimal = 0,
        dateTransaction: Date = Date(),
        isExecuted: Bool = true,
        note: String = "",
        type: TransactionType = .consumption,
        timeCreate: Date = Date()
    ) {
        self.accounting = accounting
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.id = id
        self.isExecuted = isExecuted
        self.note = note
        self.type = type
        self.timeCreate = timeCreate
        self.accountFrom = Account()
        self.accountTo = Account()
    }
    
    init(_ res: GetTransactionsRes) {
        self.accounting = res.accounting
        self.amountFrom = res.amountFrom
        self.amountTo = res.amountTo
        self.dateTransaction = res.dateTransaction
        self.id = res.id
        self.isExecuted = res.isExecuted
        self.note = res.note
        self.type = res.type
        self.timeCreate = Date()
        self.accountFrom = Account()
        self.accountTo = Account()
    }
}

enum TransactionType: String, Codable {
    case consumption, income, transfer, balancing
}
