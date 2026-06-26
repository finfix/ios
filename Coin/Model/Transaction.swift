//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import ProtoDefinitions

struct Transaction: Identifiable, Hashable {
    var id: UUID
    var accountingInCharts: Bool
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
    var accountGroupID: UUID
    /// Баланс счёта accountFrom после выполнения транзакции
    var balanceAfterFrom: Decimal
    /// Баланс счёта accountTo после выполнения транзакции
    var balanceAfterTo: Decimal

    /// Баланс счёта accountFrom до выполнения транзакции
    var balanceBeforeFrom: Decimal {
        switch type {
        case .income:
            return balanceAfterFrom - amountFrom
        case .consumption, .transfer, .balancing:
            return balanceAfterFrom + amountFrom
        }
    }

    /// Баланс счёта accountTo до выполнения транзакции
    var balanceBeforeTo: Decimal {
        balanceAfterTo - amountTo
    }

    init(
        id: UUID = UUID(),
        accountingInCharts: Bool = true,
        amountFrom: Decimal = 0,
        amountTo: Decimal = 0,
        dateTransaction: Date = Date(),
        isExecuted: Bool = true,
        note: String = "",
        type: TransactionType = .consumption,
        datetimeCreate: Date = Date(),
        accountFrom: Account = Account(),
        accountTo: Account = Account(),
        tags: [Tag] = [],
        accountGroupID: UUID = UUID(),
        balanceAfterFrom: Decimal = 0,
        balanceAfterTo: Decimal = 0
    ) {
        self.accountingInCharts = accountingInCharts
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
        self.accountGroupID = accountGroupID
        self.balanceAfterFrom = balanceAfterFrom
        self.balanceAfterTo = balanceAfterTo
    }
}

// Инициализатор из модели базы данных
extension Transaction {
    init(
        _ dbModel: TransactionDB,
        accountsMap: [UUID: Account]?,
        tagsToTransactions: [TagToTransactionDB],
        tagsMap: [UUID: Tag]?
    ) {
        self.accountingInCharts = dbModel.accountingInCharts
        self.amountFrom = dbModel.amountFrom
        self.amountTo = dbModel.amountTo
        self.dateTransaction = dbModel.dateTransaction
        self.id = dbModel.id!
        self.isExecuted = dbModel.isExecuted
        self.note = dbModel.note
        self.type = dbModel.type
        self.datetimeCreate = dbModel.datetimeCreate
        self.accountFrom = accountsMap?[dbModel.accountFromId] ?? Account()
        self.accountTo = accountsMap?[dbModel.accountToId] ?? Account()
        self.accountGroupID = dbModel.accountGroupId
        self.balanceAfterFrom = 0
        self.balanceAfterTo = 0
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
        accountsMap: [UUID: Account]?,
        tagsToTransactions: [TagToTransactionDB],
        tagsMap: [UUID: Tag]?
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

enum TransactionType: String, Codable, CaseIterable {
    case consumption, income, transfer, balancing
    
    var name: String {
        switch self {
        case .consumption: return "Расход"
        case .income: return "Доход"
        case .transfer: return "Перевод"
        case .balancing: return "Балансировка"
        }
    }
}
