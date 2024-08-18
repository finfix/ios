//
//  Service.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import OSLog
import SwiftUI
import Factory

private let logger = Logger(subsystem: "Coin", category: "Service")

@Observable
class Service {
    
    // MARK: Init
    init(
        repository: Repository,
        apiManager: APIManager,
        taskManager: TaskManager,
        authManager: AuthManager
    ) {
        self.repository = repository
        self.apiManager = apiManager
        self.taskManager = taskManager
        self.authManager = authManager
    }
    
    let repository: Repository
    let apiManager: APIManager
    let taskManager: TaskManager
    let authManager: AuthManager
}

extension Service {
    
    func deleteAllData() async throws {
        try await repository.deleteAllData()
    }
    
    func logout() async throws {
        guard try await repository.getCountTasks() == 0 else {
            throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
        }
        try await repository.deleteAllData()
        authManager.logout()
    }
        
    func joinExclusive(_ leftObjects: [Tag], _ rightObjects: [Tag]) -> ([Tag], [Tag]) {
        let leftObjectsMap = Dictionary(uniqueKeysWithValues: leftObjects.map { ($0.id, $0) })
        let rightObjectsMap = Dictionary(uniqueKeysWithValues: rightObjects.map { ($0.id, $0) })
        
        var leftObjectsExclusive: [Tag] = []
        var rightObjectsExclusive: [Tag] = []
        
        for leftObject in leftObjects {
            if rightObjectsMap[leftObject.id] == nil {
                leftObjectsExclusive.append(leftObject)
            }
        }
        
        for rightObject in rightObjects {
            if leftObjectsMap[rightObject.id] == nil {
                rightObjectsExclusive.append(rightObject)
            }
        }
        
        return (leftObjectsExclusive, rightObjectsExclusive)
    }
    
    func getStatisticByMonth(
        chartType: ChartType,
        accountGroupID: UInt32,
        accountIDs: [UInt32] = []
    ) async throws -> [Series] {
        var data: [Series] = []
        let accountsMap = Account.convertToMap(
            Account.groupAccounts(
                Account.convertFromDBModel(
                    try await repository.getAccounts(),
                    currenciesMap: nil,
                    accountGroupsMap: nil,
                    iconsMap: nil
                ),
                saveChildren: true
            )
        )
        
        switch chartType {
        case .earningsAndExpenses:
            var expenses = try await repository.getStatisticByMonth(chartType: chartType, transactionType: .consumption, accountGroupID: accountGroupID, accountIDs: accountIDs)
            if !expenses.isEmpty {
                expenses[0].type = "Расход"
                expenses[0].color = .red
                data.append(contentsOf: expenses)
            }
            var earnings = try await repository.getStatisticByMonth(chartType: chartType, transactionType: .income, accountGroupID: accountGroupID, accountIDs: accountIDs)
            if !earnings.isEmpty {
                earnings[0].type = "Доход"
                earnings[0].color = .green
                data.append(contentsOf: earnings)
            }
        case .earnings:
            data = try await repository.getStatisticByMonth(chartType: chartType, transactionType: .income, accountGroupID: accountGroupID, accountIDs: accountIDs)
        case .expenses:
            data = try await repository.getStatisticByMonth(chartType: chartType, transactionType: .consumption, accountGroupID: accountGroupID, accountIDs: accountIDs)
        }
        
        if chartType != .earningsAndExpenses {
            for (i, dataItem) in data.enumerated() {
                data[i].account = accountsMap[UInt32(dataItem.type)!]!
            }
            data = data.sorted(by: { $0.data.map{$0.value}.reduce(0){$0+$1} > $1.data.map{$0.value}.reduce(0){$0+$1} })
            for (i, _) in data.enumerated() {
                data[i].serialNumber = UInt32(i)
                data[i].color = defaultColors[i%defaultColors.count]
            }
        }
        
        var minDate: Date = .now
        var maxDate: Date = .now
        
        // Проходимся по каждой статье и получаем дату самой первой и самой последней записи
        for data in data {
            if let minDateOfData = data.data.keys.min() {
                if minDate > minDateOfData {
                    minDate = minDateOfData
                }
            }
            if let maxDateOfData = data.data.keys.max() {
                if maxDate < maxDateOfData {
                    maxDate = maxDateOfData
                }
            }
        }
        
        // Проходимся по каждой статье
        for (i, series) in data.enumerated() {
            
            // Обозначаем самую раннюю дату, которая должна быть у каждой статьи
            var lastDate: Date = minDate
            
            // Проходимся по датам, отсортированным в порядке увеличения
            while true {
                
                if series.data[lastDate] == nil {
                    data[i].data[lastDate] = 0
                }
                                
                // Обновляем последнюю проверенную дату
                lastDate = lastDate.adding(.month, value: 1)
                if lastDate > maxDate {
                    break
                }
            }
        }
        return data
    }
    
    func compareLocalAndServerData() async throws -> String? {
        guard try await repository.getCountTasks() == 0 else {
            throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
        }
        logger.log("Начали сравнение серверных данных с локальными")
        
        var differences: String = ""
        
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let serverIcons = IconDB.convertFromApiModel(try await apiManager.GetIcons())
        async let serverCurrencies = CurrencyDB.convertFromApiModel(try await apiManager.GetCurrencies())
        async let serverUser = UserDB(try await apiManager.GetUser())
        async let serverAccountGroups = AccountGroupDB.convertFromApiModel(try await apiManager.GetAccountGroups())
        async let serverAccounts = AccountDB.convertFromApiModel(try await apiManager.GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo)))
        async let serverTags = TagDB.convertFromApiModel(try await apiManager.GetTags())
        async let serverTagsToTransactions = TagToTransactionDB.convertFromApiModel(try await apiManager.GetTagsToTransaction())
        async let serverTransactions = TransactionDB.convertFromApiModel(try await apiManager.GetTransactions(req: GetTransactionReq()))
        
        var localIcons = try await repository.getIcons()
        var localCurrencies = try await repository.getCurrencies()
        var localUsers = try await repository.getUsers()
        var localAccountGroups = try await repository.getAccountGroups()
        var localAccounts = try await repository.getAccounts()
        var localTags = try await repository.getTags()
        var localTagsToTransactions = try await repository.getTagsToTransactions()
        var localTransactions = try await repository.getTransactions()
        
        let idsMapping = try await repository.getIDsMapping()
        
        let iconIDsMapping = IDMappingDB.getMapForModelType(mapping: idsMapping, modelType: .icon)
        for (i, localIcon) in localIcons.enumerated() {
            localIcons[i].id = iconIDsMapping[localIcon.id!]
        }
        let userIDsMapping = IDMappingDB.getMapForModelType(mapping: idsMapping, modelType: .user)
        for (i, localUser) in localUsers.enumerated() {
            localUsers[i].id = userIDsMapping[localUser.id!]
        }
        let accountGroupIDsMapping = IDMappingDB.getMapForModelType(mapping: idsMapping, modelType: .accountGroup)
        for (i, localAccountGroup) in localAccountGroups.enumerated() {
            localAccountGroups[i].id = accountGroupIDsMapping[localAccountGroup.id!]
        }
        let accountIDsMapping = IDMappingDB.getMapForModelType(mapping: idsMapping, modelType: .account)
        for (i, localAccount) in localAccounts.enumerated() {
            localAccounts[i].id = accountIDsMapping[localAccount.id!]
            localAccounts[i].accountGroupId = accountGroupIDsMapping[localAccount.accountGroupId]!
            localAccounts[i].iconID = iconIDsMapping[localAccount.iconID]!
        }
        let tagIDsMapping = IDMappingDB.getMapForModelType(mapping: idsMapping, modelType: .tag)
        for (i, localTag) in localTags.enumerated() {
            localTags[i].id = tagIDsMapping[localTag.id!]
            localTags[i].accountGroupID = accountGroupIDsMapping[localTag.accountGroupID]!
        }
        let transactionIDsMapping = IDMappingDB.getMapForModelType(mapping: idsMapping, modelType: .transaction)
        for (i, localTransaction) in localTransactions.enumerated() {
            localTransactions[i].id = transactionIDsMapping[localTransaction.id!]
            localTransactions[i].accountFromId = accountIDsMapping[localTransaction.accountFromId]!
            localTransactions[i].accountToId = accountIDsMapping[localTransaction.accountToId]!
        }
        
        let iconsDifferences = IconDB.compareTwoArrays(try await serverIcons, localIcons)
        if !iconsDifferences.isEmpty {
            differences += "Icons: \(iconsDifferences)"
            logger.warning("Icons: \(iconsDifferences)")
        }
        let currenciesDifferences = CurrencyDB.compareTwoArrays(try await serverCurrencies, localCurrencies)
        if !currenciesDifferences.isEmpty {
            differences += "\n\nCurrencies: \(currenciesDifferences)"
            logger.warning("Currencies: \(currenciesDifferences)")
        }
        let userDifferences = UserDB.compareTwoArrays(try await [serverUser], localUsers)
        if !userDifferences.isEmpty {
            differences += "\n\nUsers: \(userDifferences)"
            logger.warning("Users: \(userDifferences)")
        }
        let accountGroupsDifferences = AccountGroupDB.compareTwoArrays(try await serverAccountGroups, localAccountGroups)
        if !accountGroupsDifferences.isEmpty {
            differences += "\n\nAccountGroups: \(accountGroupsDifferences)"
            logger.warning("AccountGroups: \(accountGroupsDifferences)")
        }
        let accountsDifferences = AccountDB.compareTwoArrays(try await serverAccounts, localAccounts)
        if !accountsDifferences.isEmpty {
            differences += "\n\nAccounts: \(accountsDifferences)"
            logger.warning("Accounts: \(accountsDifferences)")
        }
        let tagsDifferences = TagDB.compareTwoArrays(try await serverTags, localTags)
        if !tagsDifferences.isEmpty {
            differences += "\n\nTags: \(tagsDifferences)"
            logger.warning("Tags: \(tagsDifferences)")
        }
        let tagsToTransactionsDifferences = TagToTransactionDB.compareTwoArrays(try await serverTagsToTransactions, localTagsToTransactions)
        if !tagsToTransactionsDifferences.isEmpty {
            differences += "\n\nTagsToTransactions: \(tagsToTransactionsDifferences)"
            logger.warning("TagsToTransactions: \(tagsToTransactionsDifferences)")
        }
        let transactionsDifferences = TransactionDB.compareTwoArrays(try await serverTransactions, localTransactions)
        if !transactionsDifferences.isEmpty {
            differences += "\n\nTransactions: \(transactionsDifferences)"
            logger.warning("Transactions: \(transactionsDifferences)")
        }
        if differences == "" {
            return nil
        } else {
            return differences
        }
    }
    
    func sync() async throws {
        guard try await repository.getCountTasks() == 0 else {
            throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
        }
        logger.info("Синхронизируем данные")
                
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let _icons = try await apiManager.GetIcons()
        async let _currencies = try await apiManager.GetCurrencies()
        async let _user = try await apiManager.GetUser()
        async let _accountGroups = try await apiManager.GetAccountGroups()
        async let _accounts = try await apiManager.GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
        async let _tags = try await apiManager.GetTags()
        async let _tagsToTransactions = try await apiManager.GetTagsToTransaction()
        async let _transactions = try await apiManager.GetTransactions(req: GetTransactionReq())

        var (icons, currencies, user, accountGroups, accounts, tags, tagsToTrasnactions, transactions) = try await (_icons, _currencies, _user, _accountGroups, _accounts, _tags, _tagsToTransactions, _transactions)
        
        // Загружаем и сохраняем локально иконки
        for icon in icons {
            let iconData = try await apiManager.GetIcon(url: "https://bonavii.com/"+icon.url)
            let url = URL.documentsDirectory.appending(path: String(icon.url))
            try iconData.write(to: url, options: [.atomic, .completeFileProtection])
        }
        
        // Удаляем все данные в базе данных
        try await repository.deleteAllData()
                
        // Сохраняем данные в базу данных
        logger.info("Сохраняем иконки")
        try await repository.importIcons(IconDB.convertFromApiModel(icons))
        logger.info("Сохраняем валюты")
        try await repository.importCurrencies(CurrencyDB.convertFromApiModel(currencies))
        logger.info("Сохраняем пользователя")
        try await repository.importUser(UserDB(user))
        logger.info("Сохраняем группы счетов")
        try await repository.importAccountGroups(AccountGroupDB.convertFromApiModel(accountGroups))
        logger.info("Сохраняем счета")
        try await repository.importAccounts(AccountDB.convertFromApiModel(accounts).sorted { l, _ in l.isParent })
        logger.info("Сохраняем подкатегории")
        try await repository.importTags(TagDB.convertFromApiModel(tags))
        logger.info("Сохраняем транзакции")
        try await repository.importTransactions(TransactionDB.convertFromApiModel(transactions))
        logger.info("Сохраняем связки между подкатегориями и транзакциями")
        try await repository.importTagsToTransactions(TagToTransactionDB.convertFromApiModel(tagsToTrasnactions))
    }
}

extension Decimal {
    public func round(factor: Int16) -> Decimal {
      let roundingBehavior = NSDecimalNumberHandler(
        roundingMode: .bankers,
        scale: factor,
        raiseOnExactness: true,
        raiseOnOverflow: true,
        raiseOnUnderflow: true,
        raiseOnDivideByZero: true
      )
    
      return (self as NSDecimalNumber).rounding(accordingToBehavior: roundingBehavior) as Decimal
    }
}
