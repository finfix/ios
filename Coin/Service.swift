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
    func getCurrencies() throws -> [Currency] {
        return Currency.convertFromDBModel(try db.getCurrencies())
    }
    
    func deleteAllData() throws {
        try db.deleteAllData()
    }
    
    func getAccounts(
        ids: [UInt32]? = nil
    ) throws -> [Account] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap))
        return Account.convertFromDBModel(try db.getAccounts(ids: ids), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap)
    }
    
    
    func getAccountGroups() throws -> [AccountGroup] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        return AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap)
    }
    func getFullTransactionsPage(page: Int) throws -> [Transaction] {
        let limit = 100
        
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap))
        let accountsMap = Account.convertToMap(Account.convertFromDBModel(try db.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap))
        return Transaction.convertFromDBModel(try db.getTransactionsWithPagination(offset: limit * page, limit: limit), accountsMap: accountsMap)
    }
    
    // Удаляет транзакцию из базы данных, получает актуальные счета, считает новые балансы счетов и изменяет их в базе данных
    func deleteTransaction(_ t: Transaction) async throws {
        var transaction = t
        
        try await TransactionAPI().DeleteTransaction(req: DeleteTransactionReq(id: transaction.id))
        
        let accounts = try getAccounts(ids: [transaction.accountFrom.id, transaction.accountTo.id])
        guard accounts.count == 2 else {
            showErrorAlert("Не нашли оба счета транзакции в базе данных")
            return
        }
        
        transaction.accountFrom = accounts.first { $0.id == transaction.accountFrom.id }!
        transaction.accountTo = accounts.first { $0.id == transaction.accountTo.id }!
        
        switch transaction.type {
        case .transfer, .consumption:
            transaction.accountFrom.remainder += transaction.amountFrom
            transaction.accountTo.remainder -= transaction.amountTo
        case .income:
            transaction.accountFrom.remainder -= transaction.amountFrom
            transaction.accountTo.remainder -= transaction.amountTo
        case .balancing:
            transaction.accountTo.remainder -= transaction.amountTo
        }
        
        try db.deleteTransactionAndChangeBalances(transaction)
    }
    
    func createAccount(_ a: Account) async throws {
        var account = a
        account.id = try await AccountAPI().CreateAccount(req: CreateAccountReq(
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
            isParent: false)
        )
        
        try db.createAccount(account)
    }
    
    func updateAccount(newAccount: Account, oldAccount: Account) async throws {
        
        try await AccountAPI().UpdateAccount(req: UpdateAccountReq(
            id: newAccount.id,
            accounting: oldAccount.accounting != newAccount.accounting ? newAccount.accounting : nil,
            name: oldAccount.name != newAccount.name ? newAccount.name : nil,
            remainder: oldAccount.remainder != newAccount.remainder ? newAccount.remainder : nil,
            visible: oldAccount.visible != newAccount.visible ? newAccount.visible : nil,
            budget: UpdateBudgetReq(
                amount: oldAccount.budgetAmount != newAccount.budgetAmount ? newAccount.budgetAmount : nil,
                fixedSum: oldAccount.budgetFixedSum != newAccount.budgetFixedSum ? newAccount.budgetFixedSum : nil,
                daysOffset: oldAccount.budgetDaysOffset != newAccount.budgetDaysOffset ? newAccount.budgetDaysOffset : nil,
                gradualFilling: oldAccount.budgetGradualFilling != newAccount.budgetGradualFilling ? newAccount.budgetGradualFilling : nil)
        ))
        
        try db.updateAccount(newAccount)
    }
}

// MARK: - Sync
extension Service {
    func sync() async throws {
        logger.info("Синхронизируем данные")
        
        // Сбрасываем указатель на текущую группу счета
        @AppStorage("accountGroupIndex") var selectedAccountGroupIndex: Int = 0
        @AppStorage("accountGroupID") var selectedAccountGroupID: Int?
        selectedAccountGroupID = nil
        selectedAccountGroupIndex = 0
        
        // Получаем данные текущего месяца для запроса
        // TODO: Убрать
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
        let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
        
        // Получаем все данные с сервера
        async let currencies = try await UserAPI().GetCurrencies()
        async let user = try await UserAPI().GetUser()
        async let accountGroups = try await AccountAPI().GetAccountGroups()
        async let accounts = try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
        async let transactions = try await TransactionAPI().GetTransactions(req: GetTransactionReq())
                    
        // Сохраняем данные в базу данных
        logger.info("Сохраняем валюты")
        try db.importCurrencies(CurrencyDB.convertFromApiModel(try await currencies))
        logger.info("Сохраняем пользователя")
        try db.importUser(UserDB(try await user))
        logger.info("Сохраняем группы счетов")
        try db.importAccountGroups(AccountGroupDB.convertFromApiModel(try await accountGroups))
        logger.info("Сохраняем счета")
        try db.importAccounts(AccountDB.convertFromApiModel(try await accounts))
        logger.info("Сохраняем транзакции")
        try db.importTransactions(TransactionDB.convertFromApiModel(try await transactions))
    }
}
