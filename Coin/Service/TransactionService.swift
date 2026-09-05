//
//  TransactionService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import GRDB

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
        var tagIDs: [UUID] = []
        for tag in transaction.tags {
            tagIDs.append(tag.id)
        }
        
        try validateTransaction(transaction)
        
        try await repository.createTransaction(transaction)
        try await recalculateAccountBalances(accounts: [transaction.accountFrom, transaction.accountTo])
        try await repository.linkTagsToTransaction(transaction.tags, transaction: transaction)

        try await taskManager.createTask(
            actionName: .createTransaction,
            reqModel: CreateTransactionReq(
                id: transaction.id,
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
                accountingInCharts: transaction.accountingInCharts,
                accountGroupID: transaction.accountGroupID
            ),
            entityID: transaction.id,
            dependsOnEntityIDs: [transaction.accountFrom.id, transaction.accountTo.id, transaction.accountGroupID] + tagIDs
        )

        // Транзакция затрагивает счёт-мост — заводим требование довнести для владельца другой
        // стороны моста (см. Account.linkedAccountID). Независимая задача очереди: если она не
        // долетит сразу, сама транзакция всё равно уже создана и синхронизируется.
        if let bridgeAccount = [transaction.accountFrom, transaction.accountTo].first(where: { $0.linkedAccountID != nil }),
           let targetAccountID = bridgeAccount.linkedAccountID {
            let pendingTransferID = UUID()

            try await repository.createPendingLinkedTransfer(PendingLinkedTransfer(
                id: pendingTransferID,
                status: .pending,
                sourceTransactionID: transaction.id,
                sourceAccountID: bridgeAccount.id,
                targetAccountID: targetAccountID,
                accountGroupID: transaction.accountGroupID
            ))

            try await taskManager.createTask(
                actionName: .createPendingLinkedTransfer,
                reqModel: CreatePendingLinkedTransferReq(
                    id: pendingTransferID,
                    sourceTransactionID: transaction.id,
                    sourceAccountID: bridgeAccount.id,
                    targetAccountID: targetAccountID,
                    accountGroupID: transaction.accountGroupID
                ),
                entityID: pendingTransferID,
                dependsOnEntityIDs: [transaction.id]
            )
        }
    }

    // MARK: Pending linked transfers ("счета-мосты")

    /// Живой список требований довнести — и исходящие (я источник, accountGroupID — моя группа),
    /// и входящие (я получатель, мой счёт-мост как targetAccountID, но группа исходная — чужая).
    func observePendingLinkedTransfers(accountGroups: [AccountGroup], myAccountIDs: [UUID]) -> AsyncValueObservation<[PendingLinkedTransfer]> {
        repository.observePendingLinkedTransfers(accountGroupIDs: accountGroups.map(\.id), targetAccountIDs: myAccountIDs)
    }

    /// "Не переносить" — статус-флаг, исходная транзакция-инициатор не трогается.
    func ignoreLinkedTransfer(_ transfer: PendingLinkedTransfer) async throws {
        var updated = transfer
        updated.status = .ignored
        try await repository.updatePendingLinkedTransfer(updated)
        try await taskManager.createTask(
            actionName: .updatePendingLinkedTransfer,
            reqModel: UpdatePendingLinkedTransferReq(id: transfer.id, status: .ignored),
            entityID: transfer.id
        )
    }

    /// Довнесение завершено — вызывается после успешного создания довносящей транзакции.
    func completeLinkedTransfer(_ transfer: PendingLinkedTransfer) async throws {
        var updated = transfer
        updated.status = .completed
        try await repository.updatePendingLinkedTransfer(updated)
        try await taskManager.createTask(
            actionName: .updatePendingLinkedTransfer,
            reqModel: UpdatePendingLinkedTransferReq(id: transfer.id, status: .completed),
            entityID: transfer.id
        )
    }

    // MARK: Read
    func getTransactions(
        limit: Int = 100,
        offset: Int = 0,
        ids: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        transactionTypes: [TransactionType] = [],
        currencies: [Currency] = [],
        tagIDs: [UUID] = [],
        excludedTagIDs: [UUID] = [],
        accountGroupIDs: [UUID] = []
    ) async throws -> [Transaction] {

        let dateFrom: Date? = dateFrom?.stripTime()
        let dateTo: Date? = dateTo?.stripTime()

        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await repository.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await repository.getAccountGroups(), currenciesMap: currenciesMap))
        let accountsMap = Account.convertToMap(Account.convertFromDBModel(try await repository.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap, iconsMap: nil))
        let tagsToTransactions = try await repository.getTagsToTransactions()
        let tagsMap = Tag.convertToMap(Tag.convertFromDBModel(try await repository.getTags(), accountGroupsMap: nil))
        var transactions = Transaction.convertFromDBModel(
            try await repository.getTransactions(
                limit: limit,
                offset: offset,
                ids: ids,
                dateFrom: dateFrom,
                dateTo: dateTo,
                searchText: searchText,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                accountGroupIDs: accountGroupIDs,
                transactionTypes: transactionTypes,
                currencies: currencies,
                tagIDs: tagIDs,
                excludedTagIDs: excludedTagIDs
            ),
            accountsMap: accountsMap,
            tagsToTransactions: tagsToTransactions,
            tagsMap: tagsMap
        )

        // Вычисляем балансы accountFrom и accountTo после каждой транзакции.
        // Идём от новейших к старейшим, отматывая текущий баланс назад.
        let sorted = transactions.sorted {
            if $0.dateTransaction != $1.dateTransaction { return $0.dateTransaction > $1.dateTransaction }
            return $0.datetimeCreate > $1.datetimeCreate
        }
        var runningBalances: [UUID: Decimal] = accountsMap.mapValues { $0.remainder }
        var balanceFromMap: [UUID: Decimal] = [:]
        var balanceToMap: [UUID: Decimal] = [:]
        for transaction in sorted {
            let fromId = transaction.accountFrom.id
            let toId = transaction.accountTo.id
            balanceFromMap[transaction.id] = runningBalances[fromId] ?? 0
            balanceToMap[transaction.id] = runningBalances[toId] ?? 0
            // Отматываем effect транзакции назад для обоих счетов
            switch transaction.type {
            case .income:
                runningBalances[fromId] = (runningBalances[fromId] ?? 0) - transaction.amountFrom
                runningBalances[toId] = (runningBalances[toId] ?? 0) - transaction.amountTo
            case .consumption, .transfer, .balancing:
                runningBalances[fromId] = (runningBalances[fromId] ?? 0) + transaction.amountFrom
                runningBalances[toId] = (runningBalances[toId] ?? 0) - transaction.amountTo
            }
        }
        for i in transactions.indices {
            transactions[i].balanceAfterFrom = balanceFromMap[transactions[i].id] ?? 0
            transactions[i].balanceAfterTo = balanceToMap[transactions[i].id] ?? 0
        }

        return transactions
    }

    /// Только даты, у которых есть транзакции — для горизонтального календаря. Не завязан на
    /// пагинацию списка транзакций, поэтому показывает сразу всю историю (в рамках фильтров).
    func getTransactionDays(
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        transactionTypes: [TransactionType] = [],
        currencies: [Currency] = [],
        tagIDs: [UUID] = [],
        excludedTagIDs: [UUID] = [],
        accountGroupIDs: [UUID] = []
    ) async throws -> [Date] {
        try await repository.getTransactionDays(
            dateFrom: dateFrom?.stripTime(),
            dateTo: dateTo?.stripTime(),
            searchText: searchText,
            accountIDs: accountIDs,
            excludedAccountIDs: excludedAccountIDs,
            accountGroupIDs: accountGroupIDs,
            transactionTypes: transactionTypes,
            currencies: currencies,
            tagIDs: tagIDs,
            excludedTagIDs: excludedTagIDs
        )
    }

    /// Живое окно списка транзакций — см. Repository.observeTransactionRows. dateFrom здесь —
    /// нижняя граница уже подгруженной пагинацией истории (не фильтр пользователя), поэтому
    /// вызывающий код (TransactionsListViewModel) должен передавать текущий курсор, а не
    /// исходный filters.dateFrom.
    func observeTransactionRows(
        dateFrom: Date?,
        dateTo: Date?,
        searchText: String = "",
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        transactionTypes: [TransactionType] = [],
        currencies: [Currency] = [],
        tagIDs: [UUID] = [],
        excludedTagIDs: [UUID] = [],
        accountGroupIDs: [UUID] = []
    ) -> AsyncValueObservation<[TransactionListRowData]> {
        repository.observeTransactionRows(
            dateFrom: dateFrom?.stripTime(),
            dateTo: dateTo?.stripTime(),
            searchText: searchText,
            accountIDs: accountIDs,
            excludedAccountIDs: excludedAccountIDs,
            accountGroupIDs: accountGroupIDs,
            transactionTypes: transactionTypes,
            currencies: currencies,
            tagIDs: tagIDs,
            excludedTagIDs: excludedTagIDs
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
        
        var oldTransactionTagIDs: [UUID] = []
        for tag in oldTransaction.tags {
            oldTransactionTagIDs.append(tag.id)
        }
        
        var newTransactionTagIDs: [UUID] = []
        for tag in newTransaction.tags {
            newTransactionTagIDs.append(tag.id)
        }
        
        newTransaction.dateTransaction = newTransaction.dateTransaction.stripTime()
        
        try validateTransaction(transaction)
        
        try await repository.updateTransaction(newTransaction)
        try await recalculateAccountBalances(accounts: [oldTransaction.accountFrom, oldTransaction.accountTo, newTransaction.accountFrom, newTransaction.accountTo])
        
        let (tagsToDelete, tagsToInsert) = joinExclusive(oldTransaction.tags, newTransaction.tags)
        if !tagsToDelete.isEmpty {
            try await repository.unlinkTagsFromTransaction(tagsToDelete, transaction: transaction)
        }
        if !tagsToInsert.isEmpty {
            try await repository.linkTagsToTransaction(tagsToInsert, transaction: transaction)
        }
        
        try await taskManager.createTask(
            actionName: .updateTransaction,
            reqModel: UpdateTransactionReq(
            accountFromID: newTransaction.accountFrom.id != oldTransaction.accountFrom.id ? newTransaction.accountFrom.id : nil,
            accountToID: newTransaction.accountTo.id != oldTransaction.accountTo.id ? newTransaction.accountTo.id : nil,
            amountFrom: newTransaction.amountFrom != oldTransaction.amountFrom ? newTransaction.amountFrom : nil,
            amountTo: newTransaction.amountTo != oldTransaction.amountTo ? newTransaction.amountTo : nil,
            dateTransaction: newTransaction.dateTransaction != oldTransaction.dateTransaction ? newTransaction.dateTransaction : nil,
            note: newTransaction.note != oldTransaction.note ? newTransaction.note : nil,
            tagIDs: oldTransactionTagIDs != newTransactionTagIDs ? newTransactionTagIDs : nil,
            accountingInCharts: newTransaction.accountingInCharts != oldTransaction.accountingInCharts ? newTransaction.accountingInCharts : nil,
            id: newTransaction.id),
            entityID: newTransaction.id,
            dependsOnEntityIDs: [newTransaction.accountFrom.id, newTransaction.accountTo.id] + newTransactionTagIDs
        )
    }
    
    // Удаляет транзакцию из базы данных, получает актуальные счета, считает новые балансы счетов и изменяет их в базе данных
    // MARK: Delete
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await self.repository.deleteTransaction(transaction)
        try await self.recalculateAccountBalances(accounts: [transaction.accountFrom, transaction.accountTo])
        try await taskManager.createTask(
            actionName: .deleteTransaction,
            reqModel: DeleteTransactionReq(id: transaction.id),
            entityID: transaction.id
        )
    }
        
    // MARK: Other
    private func validateTransaction(_ transaction: Transaction) throws {
        guard transaction.amountFrom != 0 && transaction.amountTo != 0 else {
            throw ErrorModel(humanText: "Транзакция не может быть с нулевой суммой списания или пополнения")
        }
    }
}
