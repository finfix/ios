//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation


class Transaction: Decodable, Identifiable {
    var accountFromID: UInt32
    var accountToID: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var id: UInt32
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    
    init(accountFromID: UInt32 = 0, accountToID: UInt32 = 0, accounting: Bool = true, amountFrom: Decimal = 0, amountTo: Decimal = 0, dateTransaction: Date = Date(), id: UInt32 = 0, isExecuted: Bool = true, note: String = "", type: TransactionType = .consumption) {
        self.accountFromID = accountFromID
        self.accountToID = accountToID
        self.accounting = accounting
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.id = id
        self.isExecuted = isExecuted
        self.note = note
        self.type = type
    }
}

enum TransactionType: String, Decodable {
    case consumption, income, transfer, balancing
}
