//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation

struct Transaction: Identifiable {
    var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var datetimeCreate: Date
    var accountFrom: Account
    var accountTo: Account
    var tags: [Tag]
    
    init(
        id: UInt32 = 0,
        accounting: Bool = true,
        amountFrom: Decimal = 0,
        amountTo: Decimal = 0,
        dateTransaction: Date = Date(),
        isExecuted: Bool = true,
        note: String = "",
        type: TransactionType = .consumption,
        datetimeCreate: Date = Date(),
        accountFrom: Account = Account(),
        accountTo: Account = Account(),
        tags: [Tag] = []
    ) {
        self.accounting = accounting
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.id = id
        self.isExecuted = isExecuted
        self.note = note
        self.type = type
        self.datetimeCreate = datetimeCreate
        self.accountFrom = accountFrom
        self.accountTo = accountTo
        self.tags = tags
    }
}

// Инициализатор из модели базы данных
extension Transaction {
    init(
        _ dbModel: TransactionDB,
        accountsMap: [UInt32: Account]?,
        tagsToTransactions: [TagToTransactionDB],
        tagsMap: [UInt32: Tag]?
    ) {
        self.accounting = dbModel.accounting
        self.amountFrom = dbModel.amountFrom
        self.amountTo = dbModel.amountTo
        self.dateTransaction = dbModel.dateTransaction
        self.id = dbModel.id
        self.isExecuted = dbModel.isExecuted
        self.note = dbModel.note
        self.type = dbModel.type
        self.datetimeCreate = dbModel.datetimeCreate
        self.accountFrom = accountsMap?[dbModel.accountFromId] ?? Account()
        self.accountTo = accountsMap?[dbModel.accountToId] ?? Account()
        var tags: [Tag] = []
        if let tagsMap = tagsMap {
            for tagToTransaction in tagsToTransactions.filter({ $0.transactionId == dbModel.id }) {
                tags.append(tagsMap[tagToTransaction.tagId] ?? Tag())
            }
        }
        self.tags = tags
    }
    
    static func convertFromDBModel(
        _ transactionsDB: [TransactionDB],
        accountsMap: [UInt32: Account]?,
        tagsToTransactions: [TagToTransactionDB],
        tagsMap: [UInt32: Tag]?
    ) -> [Transaction] {
        var transactions: [Transaction] = []
        for transactionDB in transactionsDB {
            transactions.append(Transaction(
                transactionDB,
                accountsMap: accountsMap,
                tagsToTransactions: tagsToTransactions,
                tagsMap: tagsMap)
            )
        }
        return transactions
    }
}

extension Transaction: Hashable {
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case consumption, income, transfer, balancing
}
