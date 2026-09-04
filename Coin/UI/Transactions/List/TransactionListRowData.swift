//
//  TransactionListRowData.swift
//  Coin
//

import Foundation

/// Облегчённая проекция Transaction только с тем, что реально нужно для отрисовки строки
/// списка/группировки по дням — в отличие от полного Transaction, не тащит за собой вложенные
/// Account (с их childrenAccounts, iconID и т.д.) на каждую из потенциально тысяч строк.
/// Это и позволяет держать весь список без пагинации/лимита без заметной просадки.
struct TransactionListRowData: Identifiable, Hashable {
    let id: UUID
    let dateTransaction: Date
    let type: TransactionType
    let accountFromName: String
    let accountFromType: AccountType
    let accountFromCurrency: Currency
    let accountToName: String
    let accountToCurrency: Currency
    let amountFrom: Decimal
    let amountTo: Decimal
    let note: String
    let tagNames: [String]

    init(
        id: UUID,
        dateTransaction: Date,
        type: TransactionType,
        accountFromName: String,
        accountFromType: AccountType,
        accountFromCurrency: Currency,
        accountToName: String,
        accountToCurrency: Currency,
        amountFrom: Decimal,
        amountTo: Decimal,
        note: String,
        tagNames: [String]
    ) {
        self.id = id
        self.dateTransaction = dateTransaction
        self.type = type
        self.accountFromName = accountFromName
        self.accountFromType = accountFromType
        self.accountFromCurrency = accountFromCurrency
        self.accountToName = accountToName
        self.accountToCurrency = accountToCurrency
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.note = note
        self.tagNames = tagNames
    }

    init(_ transaction: Transaction) {
        self.id = transaction.id
        self.dateTransaction = transaction.dateTransaction
        self.type = transaction.type
        self.accountFromName = transaction.accountFrom.name
        self.accountFromType = transaction.accountFrom.type
        self.accountFromCurrency = transaction.accountFrom.currency
        self.accountToName = transaction.accountTo.name
        self.accountToCurrency = transaction.accountTo.currency
        self.amountFrom = transaction.amountFrom
        self.amountTo = transaction.amountTo
        self.note = transaction.note
        self.tagNames = transaction.tags.map(\.name)
    }
}
