//
//  TransactionsListViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Factory

struct TransactionItem: Identifiable {
    let id: UUID
    let index: Int
    let transaction: Transaction
    let isNewSection: Bool
    // Заполняется только у последней транзакции дня — суммарный расход за день,
    // сконвертированный в валюту группы счетов.
    let isLastOfDay: Bool
    let dailyExpenseTotal: Decimal?
    let dailyExpenseCurrency: Currency?
}

@Observable
class TransactionsListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var transactionItems: [TransactionItem] = []
    
    var page = 0
    let pageSize = 10000
    var user: User = User()
        
    @MainActor
    func load(filters: TransactionFilters) async throws {
        
        var accountIDs: [UUID] = []
        for account in filters.accounts {
            accountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }

        var excludedAccountIDs: [UUID] = []
        for account in filters.excludedAccounts {
            excludedAccountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                excludedAccountIDs.append(childAccount.id)
            }
        }

        let transactions = try await service.getTransactions(
            limit: 1000,
            offset: 0,
            dateFrom: filters.dateFrom,
            dateTo: filters.dateTo,
            searchText: filters.searchText,
            accountIDs: accountIDs,
            excludedAccountIDs: excludedAccountIDs,
            transactionTypes: filters.transactionTypes,
            currencies: filters.currencies,
            tagIDs: filters.tags.map(\.id),
            accountGroupIDs: filters.accountGroups.map(\.id)
        )

        self.user = try await service.getUsers()[0]
        let targetCurrency = filters.accountGroups.count == 1 ? filters.accountGroups[0].currency : user.defaultCurrency

        self.transactionItems = transactions.enumerated().map({ index, transaction in

            var isNewSection = true
            if index > 0 {
                isNewSection = transactions[index].dateTransaction != transactions[index - 1].dateTransaction
            }

            var isLastOfDay = true
            if index < transactions.count - 1 {
                isLastOfDay = transactions[index].dateTransaction != transactions[index + 1].dateTransaction
            }

            var dailyExpenseTotal: Decimal?
            if isLastOfDay {
                var total: Decimal = 0
                for other in transactions where other.dateTransaction == transaction.dateTransaction && other.type == .consumption {
                    let currencyRate = targetCurrency.rate / other.accountTo.currency.rate
                    total += other.amountTo * currencyRate
                }
                if total != 0 {
                    dailyExpenseTotal = total
                }
            }

            return TransactionItem(
                id: transaction.id,
                index: index,
                transaction: transaction,
                isNewSection: isNewSection,
                isLastOfDay: isLastOfDay,
                dailyExpenseTotal: dailyExpenseTotal,
                dailyExpenseCurrency: dailyExpenseTotal != nil ? targetCurrency : nil
            )
        })
    }
        
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let index = transactionItems.firstIndex(where: { $0.id == transaction.id }) else {
            throw ErrorModel(humanText: "Не смогли найти позицию транзакции №\(transaction.id) в массиве")
        }
        _ = transactionItems.remove(at: index)
        try await service.deleteTransaction(transaction)
    }
}
