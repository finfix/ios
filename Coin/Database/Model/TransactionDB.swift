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
    var datetimeCreate: Date
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
        self.datetimeCreate = res.datetimeCreate
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
        self.datetimeCreate = model.datetimeCreate
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
    
    static func compareTwoArrays(_ serverModels: [TransactionDB], _ localModels: [TransactionDB]) -> [UInt32: [String: (server: Any, local: Any)]] {
        let serverModels = serverModels.sorted { $0.id < $1.id }
        let localModels = localModels.sorted { $0.id < $1.id }
        
        var differences: [UInt32: [String: (server: Any, local: Any)]] = [:]
        
        guard serverModels.count == localModels.count else {
            var difference: [String: (server: Any, local: Any)] = ["count": (server: serverModels.count, local: localModels.count)]
            differences[0] = difference
            return differences
        }
        
        for (i, serverModel) in serverModels.enumerated() {
            var difference: [String: (server: Any, local: Any)] = [:]
            if serverModel.id != localModels[i].id {
                difference["id"] = (server: serverModel.id, local: localModels[i].id)
            }
            if serverModel.accounting != localModels[i].accounting {
                difference["accounting"] = (server: serverModel.accounting, local: localModels[i].accounting)
            }
            if !serverModel.amountFrom.isEqual(to: localModels[i].amountFrom) {
                difference["amountFrom"] = (server: serverModel.amountFrom, local: localModels[i].amountFrom)
            }
            if !serverModel.amountTo.isEqual(to: localModels[i].amountTo) {
                difference["amountTo"] = (server: serverModel.amountTo, local: localModels[i].amountTo)
            }
            if serverModel.dateTransaction != localModels[i].dateTransaction {
                difference["dateTransaction"] = (server: serverModel.dateTransaction, local: localModels[i].dateTransaction)
            }
            if serverModel.isExecuted != localModels[i].isExecuted {
                difference["isExecuted"] = (server: serverModel.isExecuted, local: localModels[i].isExecuted)
            }
            if serverModel.note != localModels[i].note {
                difference["note"] = (server: serverModel.note, local: localModels[i].note)
            }
            if serverModel.type != localModels[i].type {
                difference["type"] = (server: serverModel.type, local: localModels[i].type)
            }
            if serverModel.datetimeCreate != localModels[i].datetimeCreate {
                difference["datetimeCreate"] = (server: serverModel.datetimeCreate, local: localModels[i].datetimeCreate)
            }
            if serverModel.accountFromId != localModels[i].accountFromId {
                difference["accountFromId"] = (server: serverModel.accountFromId, local: localModels[i].accountFromId)
            }
            if serverModel.accountToId != localModels[i].accountToId {
                difference["accountToId"] = (server: serverModel.accountToId, local: localModels[i].accountToId)
            }
            if !difference.isEmpty {
                differences[serverModel.id] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension TransactionDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accounting = Column(CodingKeys.accounting)
        static let amountFrom = Column(CodingKeys.amountFrom)
        static let amountTo = Column(CodingKeys.amountTo)
        static let dateTransaction = Column(CodingKeys.dateTransaction)
        static let isExecuted = Column(CodingKeys.isExecuted)
        static let note = Column(CodingKeys.note)
        static let type = Column(CodingKeys.type)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
        static let accountFromId = Column(CodingKeys.accountFromId)
        static let accountToId = Column(CodingKeys.accountToId)
    }
}

