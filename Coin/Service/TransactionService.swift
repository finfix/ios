//
//  TransactionService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation

extension Service {
    
    // MARK: Create
    func createTransaction(_ transaction: Transaction) async throws {
        var transaction = transaction
        
        transaction.amountFrom = transaction.amountFrom.round(factor: 7)
        transaction.amountTo = transaction.amountTo.round(factor: 7)
                
        if transaction.accountFrom.currency == transaction.accountTo.currency {
            transaction.amountTo = transaction.amountFrom
        }
        
        transaction.dateTransaction = transaction.dateTransaction.stripTime()
        transaction.datetimeCreate = Date.now
        var tagIDs: [UInt32] = []
        for tag in transaction.tags {
            tagIDs.append(tag.id)
        }
        
        try validateTransaction(transaction)
        
        let id = try await repository.createTransaction(transaction)
        transaction.id = id
        try await recalculateAccountBalance([transaction.accountFrom, transaction.accountTo])
        try await repository.linkTagsToTransaction(transaction.tags, transaction: transaction)

        taskManager.createTask(
            actionName: .createTransaction,
            localObjectID: id,
            reqModel: CreateTransactionReq(
                accountFromID: transaction.accountFrom.id,
                accountToID: transaction.accountTo.id,
                amountFrom: transaction.amountFrom,
                amountTo: transaction.amountTo,
                dateTransaction: transaction.dateTransaction,
                note: transaction.note,
                type: transaction.type.rawValue,
                isExecuted: true,
                tagIDs: tagIDs,
                datetimeCreate: transaction.datetimeCreate,
                accountingInCharts: transaction.accountingInCharts
            )
        )
    }
    
    // MARK: Read
    func getTransactions(
        limit: Int? = nil,
        offset: Int = 0,
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UInt32] = [],
        transactionType: TransactionType? = nil,
        currency: Currency? = nil
    ) async throws -> [Transaction] {
        
        let dateFrom: Date? = dateFrom?.stripTime()
        let dateTo: Date? = dateTo?.stripTime()
        
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await repository.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await repository.getAccountGroups(), currenciesMap: currenciesMap))
        let accountsMap = Account.convertToMap(Account.convertFromDBModel(try await repository.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap, iconsMap: nil))
        let tagsToTransactions = try await repository.getTagsToTransactions()
        let tagsMap = Tag.convertToMap(Tag.convertFromDBModel(try await repository.getTags(), accountGroupsMap: nil))
        return Transaction.convertFromDBModel(
            try await repository.getTransactions(
                offset: offset,
                limit: limit,
                dateFrom: dateFrom,
                dateTo: dateTo,
                searchText: searchText,
                accountIDs: accountIDs,
                transactionType: transactionType,
                currency: currency
            ),
            accountsMap: accountsMap,
            tagsToTransactions: tagsToTransactions,
            tagsMap: tagsMap
        )
    }
    
    // MARK: Update
    func updateTransaction(newTransaction transaction: Transaction, oldTransaction: Transaction) async throws {
        var newTransaction = transaction
        
        newTransaction.amountFrom = newTransaction.amountFrom.round(factor: 7)
        newTransaction.amountTo = newTransaction.amountTo.round(factor: 7)
        
        if newTransaction.accountFrom.currency == newTransaction.accountTo.currency{
            newTransaction.amountTo = newTransaction.amountFrom
        }
        
        var oldTransactionTagIDs: [UInt32] = []
        for tag in oldTransaction.tags {
            oldTransactionTagIDs.append(tag.id)
        }
        
        var newTransactionTagIDs: [UInt32] = []
        for tag in newTransaction.tags {
            newTransactionTagIDs.append(tag.id)
        }
        
        newTransaction.dateTransaction = newTransaction.dateTransaction.stripTime()
        
        try validateTransaction(transaction)
        
        try await repository.updateTransaction(newTransaction)
        try await recalculateAccountBalance([oldTransaction.accountFrom, oldTransaction.accountTo, newTransaction.accountFrom, newTransaction.accountTo])
        
        let (tagsToDelete, tagsToInsert) = joinExclusive(oldTransaction.tags, newTransaction.tags)
        if !tagsToDelete.isEmpty {
            try await repository.unlinkTagsFromTransaction(tagsToDelete, transaction: transaction)
        }
        if !tagsToInsert.isEmpty {
            try await repository.linkTagsToTransaction(tagsToInsert, transaction: transaction)
        }
        
        taskManager.createTask(
            actionName: .updateTransaction,
            localObjectID: newTransaction.id,
            reqModel: UpdateTransactionReq(
            accountFromID: newTransaction.accountFrom.id != oldTransaction.accountFrom.id ? newTransaction.accountFrom.id : nil,
            accountToID: newTransaction.accountTo.id != oldTransaction.accountTo.id ? newTransaction.accountTo.id : nil,
            amountFrom: newTransaction.amountFrom != oldTransaction.amountFrom ? newTransaction.amountFrom : nil,
            amountTo: newTransaction.amountTo != oldTransaction.amountTo ? newTransaction.amountTo : nil,
            dateTransaction: newTransaction.dateTransaction != oldTransaction.dateTransaction ? newTransaction.dateTransaction : nil,
            note: newTransaction.note != oldTransaction.note ? newTransaction.note : nil,
            tagIDs: oldTransactionTagIDs != newTransactionTagIDs ? newTransactionTagIDs : nil,
            accountingInCharts: newTransaction.accountingInCharts != oldTransaction.accountingInCharts ? newTransaction.accountingInCharts : nil,
            id: newTransaction.id))
    }
    
    // Удаляет транзакцию из базы данных, получает актуальные счета, считает новые балансы счетов и изменяет их в базе данных
    // MARK: Delete
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await self.repository.deleteTransaction(transaction)
        try await self.recalculateAccountBalance([transaction.accountFrom, transaction.accountTo])
        taskManager.createTask(
            actionName: .deleteTransaction,
            localObjectID: transaction.id,
            reqModel: DeleteTransactionReq(id: transaction.id)
        )
    }
    
    // MARK: Other
    private func validateTransaction(_ transaction: Transaction) throws {
        guard transaction.amountFrom != 0 && transaction.amountTo != 0 else {
            throw ErrorModel(humanText: "Транзакция не может быть с нулевой суммой списания или пополнения")
        }
    }
}
