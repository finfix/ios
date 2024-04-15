//
//  Service.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "Coin", category: "Service")

@Observable
class Service {
    private let db = AppDatabase.shared
    
    static let shared = makeShared()
    static func makeShared() -> Service {
        return Service()
    }
}

extension Service {
    private func recalculateAccountBalance(_ accounts: [Account]) throws {
        for account in accounts {
            var balance: Decimal?
            switch account.type {
            case .regular, .debt:
                balance = try db.getBalanceForAccount(account)
            case .expense, .earnings, .balancing:
                let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
                let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
                balance = try db.getBalanceForAccount(account, dateFrom: dateFrom, dateTo: dateTo)
            }
            guard var balance = balance else {
                throw ErrorModel(humanTextError: "Не смогли посчитать баланс счета \(account.id)")
            }
            if account.type == .earnings || account.type == .balancing {
                balance *= -1
            }
            try db.updateBalance(id: account.id, newBalance: balance)
        }
    }
    
    func getCurrencies() throws -> [Currency] {
        return Currency.convertFromDBModel(try db.getCurrencies())
    }
    
    func deleteAllData() throws {
        try db.deleteAllData()
    }
    
    func getAccounts(
        ids: [UInt32]? = nil,
        accountGroup: AccountGroup? = nil,
        visible: Bool? = nil,
        accounting: Bool? = nil,
        types: [AccountType]? = nil,
        currencyCode: String? = nil,
        isParent: Bool? = nil
    ) throws -> [Account] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap))
        return Account.convertFromDBModel(try db.getAccounts(
            ids: ids,
            accountGroupID: accountGroup?.id,
            visible: visible,
            accounting: accounting,
            types: types,
            currencyCode: currencyCode,
            isParent: isParent
        ), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap)
    }
    
    func getAccountGroups() throws -> [AccountGroup] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        return AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap)
    }
    
    func getTransactions(
        limit: Int,
        offset: Int,
        accountIDs: [UInt32] = []
    ) throws -> [Transaction] {
        
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap))
        let accountsMap = Account.convertToMap(Account.convertFromDBModel(try db.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap))
        return Transaction.convertFromDBModel(try db.getTransactionsWithPagination(
            offset: offset,
            limit: limit,
            accountIDs: accountIDs
        ), accountsMap: accountsMap)
    }
    
    // Удаляет транзакцию из базы данных, получает актуальные счета, считает новые балансы счетов и изменяет их в базе данных
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await TransactionAPI().DeleteTransaction(req: DeleteTransactionReq(id: transaction.id))
        try db.deleteTransaction(transaction)
        try recalculateAccountBalance([transaction.accountFrom, transaction.accountTo])
    }
    
    func createAccount(_ a: Account) async throws {
        var account = a
        let accountRes = try await AccountAPI().CreateAccount(req: CreateAccountReq(
            accountGroupID: account.accountGroup.id,
            accounting: account.accounting,
            budget: CreateAccountBudgetReq (
                amount: account.budgetAmount,
                gradualFilling: account.budgetGradualFilling
            ),
            currency: account.currency.code,
            iconID: 1,
            name: account.name,
            remainder: account.remainder != 0 ? account.remainder : nil,
            type: account.type.rawValue,
            isParent: account.isParent,
            parentAccountID: account.parentAccountID)
        )
        account.id = accountRes.id
        account.serialNumber = accountRes.serialNumber
        
        try db.createAccount(account)
    }
    
    func updateAccount(newAccount: Account, oldAccount: Account) async throws {
        var newAccount = newAccount
        
        // Получаем корректное значение parentAccountID для сервера
        var parentAccountIDToReq: UInt32? = nil
        if oldAccount.parentAccountID != newAccount.parentAccountID {
            if newAccount.parentAccountID == nil {
                parentAccountIDToReq = 0
            } else {
                parentAccountIDToReq = newAccount.parentAccountID
            }
        }
        
        // Обновляем счет на сервере
        let updateAccountRes = try await AccountAPI().UpdateAccount(req: UpdateAccountReq(
            id: newAccount.id,
            accounting: oldAccount.accounting != newAccount.accounting ? newAccount.accounting : nil,
            name: oldAccount.name != newAccount.name ? newAccount.name : nil,
            remainder: oldAccount.remainder != newAccount.remainder ? newAccount.remainder : nil,
            visible: oldAccount.visible != newAccount.visible ? newAccount.visible : nil,
            currencyCode: oldAccount.currency.code != newAccount.currency.code ? newAccount.currency.code : nil,
            parentAccountID: parentAccountIDToReq,
            budget: UpdateBudgetReq(
                amount: oldAccount.budgetAmount != newAccount.budgetAmount ? newAccount.budgetAmount : nil,
                fixedSum: oldAccount.budgetFixedSum != newAccount.budgetFixedSum ? newAccount.budgetFixedSum : nil,
                daysOffset: oldAccount.budgetDaysOffset != newAccount.budgetDaysOffset ? newAccount.budgetDaysOffset : nil,
                gradualFilling: oldAccount.budgetGradualFilling != newAccount.budgetGradualFilling ? newAccount.budgetGradualFilling : nil)
        ))
        
        // Если изменился баланс счета
        if oldAccount.remainder != newAccount.remainder {
            // Получаем балансировочный счет группы счетов
            var balancingAccount = try getAccounts(
                accountGroup: newAccount.accountGroup,
                types: [.balancing],
                currencyCode: newAccount.currency.code,
                isParent: false
            ).first
            
            // Если балансировочный счет не найден
            if balancingAccount == nil {
                
                // Получаем родительский балансировочный счет группы счетов
                let parentBalancingAccount = try getAccounts(
                    accountGroup: newAccount.accountGroup,
                    types: [.balancing],
                    isParent: true
                ).first
                
                guard parentBalancingAccount != nil else {
                    throw ErrorModel(humanTextError: "Не смогли найти родительский балансировочный счет для группы счетов \(newAccount.accountGroup.id)")
                }
                
                guard updateAccountRes.balancingAccountID != nil && updateAccountRes.balancingAccountSerialNumber != nil else {
                    throw ErrorModel(humanTextError: "На сервере не создавался балансировочный счет")
                }
                
                guard updateAccountRes.balancingTransactionID != nil else {
                    throw ErrorModel(humanTextError: "На сервере не создавалась балансировочная транзакция")
                }
                                
                // Создаем и получаем балансировочный счет группы счетов
                balancingAccount = Account.convertFromDBModel(try [db.createAccountAndReturn(Account(
                    id: updateAccountRes.balancingAccountID!,
                    accounting: true,
                    iconID: 0,
                    name: "Балансировочный",
                    remainder: 0,
                    type: .balancing,
                    visible: true,
                    serialNumber: updateAccountRes.balancingAccountSerialNumber!,
                    isParent: false,
                    budgetAmount: 0,
                    showingBudgetAmount: 0,
                    budgetFixedSum: 0,
                    budgetDaysOffset: 0,
                    budgetGradualFilling: false,
                    parentAccountID: parentBalancingAccount!.id,
                    accountGroup: newAccount.accountGroup,
                    currency: newAccount.currency,
                    childrenAccounts: []
                ))], currenciesMap: nil, accountGroupsMap: nil).first
            }
            
            try db.createTransaction(Transaction(
                id: updateAccountRes.balancingTransactionID!,
                accounting: true,
                amountFrom: newAccount.remainder-oldAccount.remainder,
                amountTo: newAccount.remainder-oldAccount.remainder,
                dateTransaction: Date.now.stripTime(),
                isExecuted: true,
                note: "",
                type: .balancing,
                timeCreate: Date.now,
                accountFrom: balancingAccount!,
                accountTo: newAccount)
            )
            
            try recalculateAccountBalance([balancingAccount!])
        }
        
        // Получаем родительский счет
        var parentAccount: Account?
        if let parentAccountID = newAccount.parentAccountID {
            parentAccount = try getAccounts(ids: [parentAccountID]).first
        }
        
        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if parentAccount != nil && !parentAccount!.accounting && newAccount.accounting {
            parentAccount!.accounting = true
        }
        
        // Если значения дочерних счетов положительные, а значение родительского отрицательное
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            if childAccount.accounting && !newAccount.accounting {
                newAccount.childrenAccounts[i].accounting = false
            }
        }
        
        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if parentAccount != nil && !parentAccount!.visible && newAccount.visible {
            parentAccount!.visible = true
        }
        
        // Если значения родительского счета меняется, то значения дочерних счетов меняются на такое же
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            newAccount.childrenAccounts[i].visible = newAccount.visible
            if !childAccount.visible && childAccount.accounting {
                newAccount.childrenAccounts[i].accounting = false
            }
        }
        
        if let parentAccount = parentAccount {
            try db.updateAccount(parentAccount)
        }

        for childAccount in newAccount.childrenAccounts {
            try db.updateAccount(childAccount)
        }
        
        try db.updateAccount(newAccount)
    }
    
    func deleteAccount(_ account: Account) async throws {
        
        try await AccountAPI().DeleteAccount(req: DeleteAccountReq(id: account.id))
        
        // Если у счета есть дочерние счета
        for childAccount in account.childrenAccounts {
            var childAccount = childAccount
            childAccount.parentAccountID = nil
            try db.updateAccount(childAccount)
        }
        
        // Удаляем счет
        try db.deleteAccount(account)
    }
    
    func createTransaction(_ t: Transaction) async throws {
        var transaction = t
        
        if transaction.accountFrom.currency == transaction.accountTo.currency {
            transaction.amountTo = transaction.amountFrom
        }
        
        transaction.dateTransaction = transaction.dateTransaction.stripTime()
        
        transaction.id = try await TransactionAPI().CreateTransaction(req: CreateTransactionReq(
            accountFromID: transaction.accountFrom.id,
            accountToID: transaction.accountTo.id,
            amountFrom: transaction.amountFrom,
            amountTo: transaction.amountTo,
            dateTransaction: transaction.dateTransaction,
            note: transaction.note,
            type: transaction.type.rawValue,
            isExecuted: true
        ))
        
        try db.createTransaction(transaction)
        try recalculateAccountBalance([transaction.accountFrom, transaction.accountTo])
    }
    
    func updateTransaction(newTransaction t: Transaction, oldTransaction: Transaction) async throws {
        var newTransaction = t
        
        if newTransaction.accountFrom.currency == newTransaction.accountTo.currency{
            newTransaction.amountTo = newTransaction.amountFrom
        }
        
        newTransaction.dateTransaction = newTransaction.dateTransaction.stripTime()
        try await TransactionAPI().UpdateTransaction(req: UpdateTransactionReq(
            accountFromID: newTransaction.accountFrom.id != oldTransaction.accountFrom.id ? newTransaction.accountFrom.id : nil,
            accountToID: newTransaction.accountTo.id != oldTransaction.accountTo.id ? newTransaction.accountTo.id : nil,
            amountFrom: newTransaction.amountFrom != oldTransaction.amountFrom ? newTransaction.amountFrom : nil,
            amountTo: newTransaction.amountTo != oldTransaction.amountTo ? newTransaction.amountTo : nil,
            dateTransaction: newTransaction.dateTransaction != oldTransaction.dateTransaction ? newTransaction.dateTransaction : nil,
            note: newTransaction.note != oldTransaction.note ? newTransaction.note : nil,
            id: newTransaction.id))
        
        try db.updateTransaction(newTransaction)
        try recalculateAccountBalance([oldTransaction.accountFrom, oldTransaction.accountTo, newTransaction.accountFrom, newTransaction.accountTo])
    }
}

// MARK: - Sync
extension Service {
    func sync() async throws {
        logger.info("Синхронизируем данные")
                
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let currencies = try await UserAPI().GetCurrencies()
        async let user = try await UserAPI().GetUser()
        async let accountGroups = try await AccountAPI().GetAccountGroups()
        async let accounts = try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
        async let transactions = try await TransactionAPI().GetTransactions(req: GetTransactionReq())
        
        // Удаляем все данные в базе данных
        try db.deleteAllData()
        
        // Сохраняем данные в базу данных
        logger.info("Сохраняем валюты")
        try db.importCurrencies(CurrencyDB.convertFromApiModel(try await currencies))
        logger.info("Сохраняем пользователя")
        try db.importUser(UserDB(try await user))
        logger.info("Сохраняем группы счетов")
        try db.importAccountGroups(AccountGroupDB.convertFromApiModel(try await accountGroups))
        logger.info("Сохраняем счета")
        // Cортируем счета, чтобы сначала были родительские
        let sortedAccountsDB = AccountDB.convertFromApiModel(try await accounts).sorted { l, _ in
            l.isParent
        }
        try db.importAccounts(sortedAccountsDB)
        logger.info("Сохраняем транзакции")
        try db.importTransactions(TransactionDB.convertFromApiModel(try await transactions))
    }
}
