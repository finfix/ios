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
        await deleteAll()
        logger.info("Синхронизируем данные")
        do {
            // Получаем все данные
            async let c = getCurrencies()
            async let u = getUser()
            async let ag = getAccountGroups()
            async let a = getAccounts()
            async let t = getTransactions()
                        
            // Сохраняем валюты
            let currencies = try await c
            for currency in currencies {
            logger.info("Получаем валюты")
                modelContext.insert(currency)
            }
            let currenciesMap = Dictionary(uniqueKeysWithValues: currencies.map { ($0.isoCode, $0) })
            
            // Сохраняем юзера
            let user = try await u
            guard let currency = currenciesMap[user.defaultCurrencyName] else {
                throw ErrorModel(developerTextError: "Не смогли найти валюту")
            }
            user.currency = currency
            modelContext.insert(user)
            logger.info("Получаем пользователя")
            
            // Сохраняем группы счетов
            let accountGroups = try await ag
            for accountGroup in accountGroups {
                guard let currency = currenciesMap[accountGroup.currencyName] else {
                    throw ErrorModel(developerTextError: "Не смогли найти валюту")
                }
                accountGroup.currency = currency
            logger.info("Получаем группы счетов")
                modelContext.insert(accountGroup)
            }
            let accountGroupsMap = Dictionary(uniqueKeysWithValues: accountGroups.map { ($0.id, $0) })
            
            // Сохраняем счета
            let accounts = try await a
            for account in accounts {
                guard let currency = currenciesMap[account.currencyName] else {
                    throw ErrorModel(developerTextError: "Не смогли найти валюту")
                }
                account.currency = currency
                guard let accountGroup = accountGroupsMap[account.accountGroupID] else {
                    throw ErrorModel(developerTextError: "Не смогли найти группу счетов")
                }
                account.accountGroup = accountGroup
            logger.info("Получаем счета счетов")
                modelContext.insert(account)
            }
            let accountsMap = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
            
            // Сохраняем транзакции
            let transactions = try await t
            for transaction in transactions {
                transaction.accountFrom = accountsMap[transaction.accountFromID]
                transaction.accountTo = accountsMap[transaction.accountToID]
            logger.info("Получаем транзакции")
                modelContext.insert(transaction)
            }
            logger.info("Все сохраняем")
        } catch {
            logger.error("\(error)")
            showErrorAlert(error.localizedDescription)
        }
    }
    
    func deleteAll() async {
        logger.info("Удаляем все данные")
        do {
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: Transaction.self)
            try modelContext.delete(model: Account.self)
            try modelContext.delete(model: Currency.self)
            try modelContext.delete(model: AccountGroup.self)
        } catch {
            debugLog(error)
            showErrorAlert(error.localizedDescription)
        }
    }
    
    private func getCurrencies() async throws -> [Currency] {
        return try await UserAPI().GetCurrencies()
    }
    
    private func getTransactions() async throws -> [Transaction] {
        return try await TransactionAPI().GetTransactions(req: GetTransactionReq())
    }
    
    private func getAccountGroups() async throws -> [AccountGroup] {
        return try await AccountAPI().GetAccountGroups()
    }
    
    private func getAccounts() async throws -> [Account] {
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
        let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
        
        return try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
    }
    
    private func getUser() async throws -> User {
        return try await UserAPI().GetUser()
    }
}
