//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct TransactionDB {
    
    var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var timeCreate: Date
    var accountFromId: UInt32
    var accountToId: UInt32
    
    // Инициализатор из сетевой модели
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
        self.accountFromId = res.accountFromID
        self.accountToId = res.accountToID
    }
    
    // Инициализатор из бизнес модели
    init(_ model: Transaction) {
        self.accounting = model.accounting
        self.amountFrom = model.amountFrom
        self.amountTo = model.amountTo
        self.dateTransaction = model.dateTransaction
        self.id = model.id
        self.isExecuted = model.isExecuted
        self.note = model.note
        self.type = model.type
        self.timeCreate = model.dateTransaction
        self.accountFromId = model.accountFrom.id
        self.accountToId = model.accountTo.id
    }
    
    static func convertFromApiModel(_ transactions: [GetTransactionsRes]) -> [TransactionDB] {
        var transactionsDB: [TransactionDB] = []
        for transaction in transactions {
            transactionsDB.append(TransactionDB(transaction))
        }
        return transactionsDB
    }
}

// MARK: - Persistence
extension TransactionDB: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let accounting = Column(CodingKeys.accounting)
        static let amountFrom = Column(CodingKeys.amountFrom)
        static let amountTo = Column(CodingKeys.amountTo)
        static let dateTransaction = Column(CodingKeys.dateTransaction)
        static let isExecuted = Column(CodingKeys.isExecuted)
        static let note = Column(CodingKeys.note)
        static let type = Column(CodingKeys.type)
        static let timeCreate = Column(CodingKeys.timeCreate)
        static let accountFromId = Column(CodingKeys.accountFromId)
        static let accountToId = Column(CodingKeys.accountToId)
    }
}

