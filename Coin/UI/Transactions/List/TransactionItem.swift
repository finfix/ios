//
//  TransactionsListViewModel.swift
//  Coin
//

import Foundation
import Factory
import GRDB

struct TransactionItem: Identifiable {
    let id: UUID
    let index: Int
    let transaction: TransactionListRowData
    let isNewSection: Bool
    // Заполняется только у последней транзакции дня — суммарный расход за день,
    // сконвертированный в валюту группы счетов.
    let isLastOfDay: Bool
    let dailyExpenseTotal: Decimal?
    let dailyExpenseCurrency: Currency?
}
