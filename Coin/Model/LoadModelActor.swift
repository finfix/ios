//
//  LoadModelActor.swift
//  Coin
//
//  Created by Илья on 13.11.2023.
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "loading data from server")

actor LoadModelActor: ModelActor {
    let modelContainer: ModelContainer
    let modelExecutor: any ModelExecutor
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
    
    func sync() async {
        logger.info("Синхронизируем данные")
        await deleteAll(isSave: false)
        do {
            // Получаем все данные
            async let c = getCurrencies()
            async let u = getUser()
            async let ag = getAccountGroups()
            async let a = getAccounts()
            async let t = getTransactions()
                        
            // Сохраняем валюты
            logger.info("Получаем валюты")
            let currenciesRes = try await c
            var currenciesMap: [String: Currency] = [:]
            for currencyRes in currenciesRes {
                let currency = Currency(currencyRes)
                currenciesMap[currency.isoCode] = currency
                modelContext.insert(currency)
            }
            
            // Сохраняем юзера
            logger.info("Получаем пользователя")
            let userRes = try await u
            modelContext.insert(User(userRes, currenciesMap: currenciesMap))
            
            // Сохраняем группы счетов
            logger.info("Получаем группы счетов")
            let accountGroupsRes = try await ag
            var accountGroupsMap: [UInt32: AccountGroup] = [:]
            for accountGroupRes in accountGroupsRes {
                let accountGroup = AccountGroup(accountGroupRes, currenciesMap: currenciesMap)
                accountGroupsMap[accountGroup.id] = accountGroup
                modelContext.insert(accountGroup)
            }
            
            // Сохраняем счета
            logger.info("Получаем счета счетов")
            let accountsRes = try await a
            var accountsMap: [UInt32: Account] = [:]
            for accountRes in accountsRes {
                let account = Account(accountRes, currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap)
                accountsMap[account.id] = account
                modelContext.insert(account)
            }
            
            // Сохраняем транзакции
            logger.info("Получаем транзакции")
            let transactionsRes = try await t
            for transactionRes in transactionsRes {
                let transaction = Transaction(transactionRes, accountsMap: accountsMap)
                modelContext.insert(transaction)
            }
            
            logger.info("Все сохраняем")
            try modelContext.save()
        } catch {
            logger.error("\(error)")
            showErrorAlert(error.localizedDescription)
        }
    }
    
    func deleteAll(isSave: Bool = true) async {
        logger.info("Удаляем все данные")
        do {
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: Transaction.self)
            try modelContext.delete(model: Account.self)
            try modelContext.delete(model: Currency.self)
            try modelContext.delete(model: AccountGroup.self)
            if isSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            logger.error("\(error)")
            showErrorAlert(error.localizedDescription)
        }
    }
    
    private func getCurrencies() async throws -> [GetCurrenciesRes] {
        return try await UserAPI().GetCurrencies()
    }
    
    private func getTransactions() async throws -> [GetTransactionsRes] {
        return try await TransactionAPI().GetTransactions(req: GetTransactionReq())
    }
    
    private func getAccountGroups() async throws -> [GetAccountGroupsRes] {
        return try await AccountAPI().GetAccountGroups()
    }
    
    private func getAccounts() async throws -> [GetAccountsRes] {
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
        let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
        
        return try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
    }
    
    private func getUser() async throws -> GetUserRes {
        return try await UserAPI().GetUser()
    }
}
