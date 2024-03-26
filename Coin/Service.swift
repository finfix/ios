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
    func isDatabaseEmpty() async -> Bool {
        return true
    }
    
    func getCurrencies() throws -> [Currency] {
        return Currency.convertFromDBModel(try db.getCurrencies())
    }
    
    func deleteAllData() throws {
        try db.deleteAllData()
    }
    
    func getFilledAccounts() throws -> [Account] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: currenciesMap))
        return Account.convertFromDBModel(try db.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap)
    }
    
    
    func getSimpleAccountGroups() throws -> [AccountGroup] {
        return AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: nil)
    }
    func getFullTransactionsPage(page: Int) throws -> [Transaction] {
        let limit = 100
        
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try db.getAccountGroups(), currenciesMap: nil))
        let accountsMap = Account.convertToMap(Account.convertFromDBModel(try db.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap))
        return Transaction.convertFromDBModel(try db.getTransactionsWithPagination(offset: limit * page, limit: limit), accountsMap: accountsMap)
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
        logger.info("Получаем валюты")
        try db.importCurrencies(CurrencyDB.convertFromApiModel(try await currencies))
        logger.info("Получаем пользователя")
        try db.importUser(UserDB(try await user))
        logger.info("Получаем группы счетов")
        try db.importAccountGroups(AccountGroupDB.convertFromApiModel(try await accountGroups))
        logger.info("Получаем счета")
        try db.importAccounts(AccountDB.convertFromApiModel(try await accounts))
        logger.info("Получаем транзакции")
        try db.importTransactions(TransactionDB.convertFromApiModel(try await transactions))
    }
}
