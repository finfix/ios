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
    private func recalculateAccountBalance(_ accounts: [Account]) async throws {
        for account in accounts {
            var balance: Decimal?
            switch account.type {
            case .regular, .debt:
                balance = try await db.getBalanceForAccount(account)
            case .expense, .earnings, .balancing:
                let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
                let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
                balance = try await db.getBalanceForAccount(account, dateFrom: dateFrom, dateTo: dateTo)
            }
            guard var balance = balance else {
                throw ErrorModel(humanTextError: "Не смогли посчитать баланс счета \(account.id)")
            }
            if account.type == .earnings || account.type == .balancing {
                balance *= -1
            }
            try await db.updateBalance(id: account.id, newBalance: balance.round(factor: 7))
        }
    }
    
    func getCurrencies() async throws -> [Currency] {
        return Currency.convertFromDBModel(try await db.getCurrencies())
    }
    
    func deleteAllData() async throws {
        try await db.deleteAllData()
    }
    
    func getTags(
        accountGroup: AccountGroup? = nil
    ) async throws -> [Tag] {
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await db.getAccountGroups(), currenciesMap: nil))
        return Tag.convertFromDBModel(try await db.getTags(
            accountGroupID: accountGroup?.id
        ), accountGroupsMap: accountGroupsMap)
    }
    
    func getAccounts(
        ids: [UInt32]? = nil,
        accountGroup: AccountGroup? = nil,
        visible: Bool? = nil,
        accountingInHeader: Bool? = nil,
        types: [AccountType]? = nil,
        currencyCode: String? = nil,
        isParent: Bool? = nil
    ) async throws -> [Account] {
        let iconsMap = Icon.convertToMap(Icon.convertFromDBModel(try await db.getIcons()))
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await db.getAccountGroups(), currenciesMap: currenciesMap))
        return Account.convertFromDBModel(try await db.getAccounts(
            ids: ids,
            accountGroupID: accountGroup?.id,
            visible: visible,
            accountingInHeader: accountingInHeader,
            types: types,
            currencyCode: currencyCode,
            isParent: isParent
        ), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap, iconsMap: iconsMap)
    }
    
    func getAccountGroups() async throws -> [AccountGroup] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await db.getCurrencies()))
        return AccountGroup.convertFromDBModel(try await db.getAccountGroups(), currenciesMap: currenciesMap)
    }
    
    func getIcons() async throws -> [Icon] {
        return Icon.convertFromDBModel(try await db.getIcons())
    }
    
    func getTransactions(
        limit: Int? = nil,
        offset: Int = 0,
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UInt32] = []
    ) async throws -> [Transaction] {
        
        let dateFrom: Date? = dateFrom?.stripTime()
        let dateTo: Date? = dateTo?.stripTime()
        
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await db.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await db.getAccountGroups(), currenciesMap: currenciesMap))
        let accountsMap = Account.convertToMap(Account.convertFromDBModel(try await db.getAccounts(), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap, iconsMap: nil))
        let tagsToTransactions = try await db.getTagsToTransactions()
        let tagsMap = Tag.convertToMap(Tag.convertFromDBModel(try await db.getTags(), accountGroupsMap: nil))
        return Transaction.convertFromDBModel(
            try await db.getTransactions(
                offset: offset,
                limit: limit,
                dateFrom: dateFrom,
                dateTo: dateTo,
                searchText: searchText,
                accountIDs: accountIDs
            ),
            accountsMap: accountsMap,
            tagsToTransactions: tagsToTransactions,
            tagsMap: tagsMap
        )
    }
    
    // Удаляет транзакцию из базы данных, получает актуальные счета, считает новые балансы счетов и изменяет их в базе данных
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await TransactionAPI().DeleteTransaction(req: DeleteTransactionReq(id: transaction.id))
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.db.deleteTransaction(transaction)
            }
            group.addTask {
                try await self.recalculateAccountBalance([transaction.accountFrom, transaction.accountTo])
            }
            
            try await group.waitForAll()
        }
    }
    
    func deleteTag(_ tag: Tag) async throws {
        try await TagAPI().DeleteTag(req: DeleteTagReq(id: tag.id))
        try await self.db.deleteTag(tag)
    }
    
    func createAccount(_ account: Account) async throws {
        var account = account
        
        account.remainder = account.remainder.round(factor: 6)
        
        try validateAccount(account)
        
        let accountRes = try await AccountAPI().CreateAccount(req: CreateAccountReq(
            accountGroupID: account.accountGroup.id,
            accountingInHeader: account.accountingInHeader,
            accountingInCharts: account.accountingInCharts,
            budget: CreateAccountBudgetReq (
                amount: account.budgetAmount,
                gradualFilling: account.budgetGradualFilling
            ),
            currency: account.currency.code,
            iconID: account.icon.id,
            name: account.name,
            remainder: account.remainder != 0 ? account.remainder : nil,
            type: account.type.rawValue,
            isParent: account.isParent,
            parentAccountID: account.parentAccountID,
            datetimeCreate: account.datetimeCreate
        )
        )
        account.id = accountRes.id
        account.serialNumber = accountRes.serialNumber
        
        try await db.createAccount(account)
    }
    
    private func validateAccount(_ account: Account) throws {
        guard account.name != "" else {
            throw ErrorModel(humanTextError: "Имя счета не может быть пустым")
        }
        
        guard account.budgetAmount >= 0 else {
            throw ErrorModel(humanTextError: "Бюджет не может быть отрицательным")
        }
        
        guard account.budgetFixedSum >= 0 else {
            throw ErrorModel(humanTextError: "Фиксированная сумма бюджета не может быть отрицательной")
        }
        
        guard account.budgetDaysOffset >= 0 else {
            throw ErrorModel(humanTextError: "Количество дней отступа не может быть отрицательным")
        }
        
        guard account.budgetFixedSum <= account.budgetAmount else {
            throw ErrorModel(humanTextError: "Фиксированная сумма бюджета не может быть больше бюджета")
        }
        
        guard account.budgetDaysOffset < Calendar.current.range(of: .day, in: .month, for: Date())!.count else {
            throw ErrorModel(humanTextError: "Количество дней отступа не может быть больше или равно количеству дней в месяце")
        }
    }
    
    func updateAccount(newAccount: Account, oldAccount: Account) async throws {
        var newAccount = newAccount
        
        newAccount.remainder = newAccount.remainder.round(factor: 6)
        
        // Получаем корректное значение parentAccountID для сервера
        var parentAccountIDToReq: UInt32? = nil
        if oldAccount.parentAccountID != newAccount.parentAccountID {
            if newAccount.parentAccountID == nil {
                parentAccountIDToReq = 0
            } else {
                parentAccountIDToReq = newAccount.parentAccountID
            }
        }
        
        try validateAccount(newAccount)

        // Обновляем счет на сервере
        let updateAccountRes = try await AccountAPI().UpdateAccount(req: UpdateAccountReq(
            id: newAccount.id,
            accountingInHeader: oldAccount.accountingInHeader != newAccount.accountingInHeader ? newAccount.accountingInHeader : nil,
            accountingInCharts: oldAccount.accountingInCharts != newAccount.accountingInCharts ? newAccount.accountingInCharts : nil,
            name: oldAccount.name != newAccount.name ? newAccount.name : nil,
            remainder: oldAccount.remainder != newAccount.remainder ? newAccount.remainder : nil,
            visible: oldAccount.visible != newAccount.visible ? newAccount.visible : nil,
            currencyCode: oldAccount.currency.code != newAccount.currency.code ? newAccount.currency.code : nil,
            parentAccountID: parentAccountIDToReq,
            iconID: oldAccount.icon != newAccount.icon ? newAccount.icon.id : nil,
            budget: UpdateBudgetReq(
                amount: oldAccount.budgetAmount != newAccount.budgetAmount ? newAccount.budgetAmount : nil,
                fixedSum: oldAccount.budgetFixedSum != newAccount.budgetFixedSum ? newAccount.budgetFixedSum : nil,
                daysOffset: oldAccount.budgetDaysOffset != newAccount.budgetDaysOffset ? newAccount.budgetDaysOffset : nil,
                gradualFilling: oldAccount.budgetGradualFilling != newAccount.budgetGradualFilling ? newAccount.budgetGradualFilling : nil)
        ))
        
        // Если изменился баланс счета
        if oldAccount.remainder != newAccount.remainder {
            // Получаем балансировочный счет группы счетов
            var balancingAccount = try await getAccounts(
                accountGroup: newAccount.accountGroup,
                types: [.balancing],
                currencyCode: newAccount.currency.code,
                isParent: false
            ).first
            
            // Если балансировочный счет не найден
            if balancingAccount == nil {
                
                // Получаем родительский балансировочный счет группы счетов
                let parentBalancingAccount = try await getAccounts(
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
                balancingAccount = Account.convertFromDBModel(try await [db.createAccountAndReturn(Account(
                    id: updateAccountRes.balancingAccountID!,
                    accountingInHeader: true,
                    accountingInCharts: true,
                    icon: Icon(),
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
                ))], currenciesMap: nil, accountGroupsMap: nil, iconsMap: nil).first
            }
            
            try await db.createTransaction(Transaction(
                id: updateAccountRes.balancingTransactionID!,
                accounting: true,
                amountFrom: newAccount.remainder-oldAccount.remainder,
                amountTo: newAccount.remainder-oldAccount.remainder,
                dateTransaction: Date.now.stripTime(),
                isExecuted: true,
                note: "",
                type: .balancing,
                datetimeCreate: Date.now,
                accountFrom: balancingAccount!,
                accountTo: newAccount)
            )
            
            try await recalculateAccountBalance([balancingAccount!])
        }
        
        // Получаем родительский счет
        var parentAccount: Account?
        if let parentAccountID = newAccount.parentAccountID {
            parentAccount = try await getAccounts(ids: [parentAccountID]).first
        }
        
        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if parentAccount != nil && !parentAccount!.accountingInHeader && newAccount.accountingInHeader {
            parentAccount!.accountingInHeader = true
        }
        
        // Если значения дочерних счетов положительные, а значение родительского отрицательное
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            if childAccount.accountingInHeader && !newAccount.accountingInHeader {
                newAccount.childrenAccounts[i].accountingInHeader = false
            }
        }
        
        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if parentAccount != nil && !parentAccount!.visible && newAccount.visible {
            parentAccount!.visible = true
        }
        
        // Если значения родительского счета меняется, то значения дочерних счетов меняются на такое же
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            newAccount.childrenAccounts[i].visible = newAccount.visible
            if !childAccount.visible && childAccount.accountingInHeader {
                newAccount.childrenAccounts[i].accountingInHeader = false
            }
        }
        
        if let parentAccount = parentAccount {
            try await db.updateAccount(parentAccount)
        }

        for childAccount in newAccount.childrenAccounts {
            try await db.updateAccount(childAccount)
        }
        
        try await db.updateAccount(newAccount)
    }
    
    func deleteAccount(_ account: Account) async throws {
        
        try await AccountAPI().DeleteAccount(req: DeleteAccountReq(id: account.id))
        
        // Если у счета есть дочерние счета
        for childAccount in account.childrenAccounts {
            var childAccount = childAccount
            childAccount.parentAccountID = nil
            try await db.updateAccount(childAccount)
        }
        
        // Удаляем счет
        try await db.deleteAccount(account)
    }
    
    func createTag(_ tag: Tag) async throws {
        var tag = tag
        
        tag.datetimeCreate = Date.now
        
        tag.id = try await TagAPI().CreateTag(req: CreateTagReq(
            name: tag.name,
            accountGroupID: tag.accountGroup.id,
            datetimeCreate: tag.datetimeCreate
        ))
        
        try await db.createTag(tag)
    }
    
    private func validateTransaction(_ transaction: Transaction) throws {
        guard transaction.amountFrom != 0 && transaction.amountTo != 0 else {
            throw ErrorModel(humanTextError: "Транзакция не может быть с нулевой суммой списания или пополнения")
        }
    }
    
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
        
        transaction.id = try await TransactionAPI().CreateTransaction(req: CreateTransactionReq(
            accountFromID: transaction.accountFrom.id,
            accountToID: transaction.accountTo.id,
            amountFrom: transaction.amountFrom,
            amountTo: transaction.amountTo,
            dateTransaction: transaction.dateTransaction,
            note: transaction.note,
            type: transaction.type.rawValue,
            isExecuted: true,
            tagIDs: tagIDs,
            datetimeCreate: transaction.datetimeCreate
        ))
        
        try await db.createTransaction(transaction)
        try await recalculateAccountBalance([transaction.accountFrom, transaction.accountTo])
        try await db.linkTagsToTransaction(transaction.tags, transaction: transaction)
    }
        
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
        
        try await TransactionAPI().UpdateTransaction(req: UpdateTransactionReq(
            accountFromID: newTransaction.accountFrom.id != oldTransaction.accountFrom.id ? newTransaction.accountFrom.id : nil,
            accountToID: newTransaction.accountTo.id != oldTransaction.accountTo.id ? newTransaction.accountTo.id : nil,
            amountFrom: newTransaction.amountFrom != oldTransaction.amountFrom ? newTransaction.amountFrom : nil,
            amountTo: newTransaction.amountTo != oldTransaction.amountTo ? newTransaction.amountTo : nil,
            dateTransaction: newTransaction.dateTransaction != oldTransaction.dateTransaction ? newTransaction.dateTransaction : nil,
            note: newTransaction.note != oldTransaction.note ? newTransaction.note : nil,
            tagIDs: oldTransactionTagIDs != newTransactionTagIDs ? newTransactionTagIDs : nil,
            id: newTransaction.id))
        
        try await db.updateTransaction(newTransaction)
        try await recalculateAccountBalance([oldTransaction.accountFrom, oldTransaction.accountTo, newTransaction.accountFrom, newTransaction.accountTo])
        
        let (tagsToDelete, tagsToInsert) = joinExclusive(oldTransaction.tags, newTransaction.tags)
        if !tagsToDelete.isEmpty {
            try await db.unlinkTagsFromTransaction(tagsToDelete, transaction: transaction)
        }
        if !tagsToInsert.isEmpty {
            try await db.linkTagsToTransaction(tagsToInsert, transaction: transaction)
        }
    }
    
    func updateTag(newTag tag: Tag, oldTag: Tag) async throws {
        var newTag = tag
        
        guard tag.name != "" else {
            throw ErrorModel(humanTextError: "Нельзя создать подкатегорию без названия")
        }
        
        try await TagAPI().UpdateTag(req: UpdateTagReq(
            id: newTag.id,
            name: newTag.name != oldTag.name ? newTag.name : nil
        ))
        
        try await db.updateTag(newTag)
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
    
    func getStatisticByMonth(accountGroupID: UInt32) async throws -> [Series] {
        var data: [Series] = []
        let expenses = try await db.getStatisticByMonth(transactionType: .consumption, accountGroupID: accountGroupID)
        data.append(Series(name: "Расходы", data: expenses))
        let incomes = try await db.getStatisticByMonth(transactionType: .income, accountGroupID: accountGroupID)
        data.append(Series(name: "Доходы", data: incomes))
        return data
    }
    
    func getServerVersion() async throws -> (String, String) {
        let versionModel = try await SettingsAPI().GetVersion()
        return (versionModel.version, versionModel.build)
    }
    
    func compareLocalAndServerData() async throws -> String? {
        logger.log("Начали сравнение серверных данных с локальными")
        
        var differences: String = ""
        
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let serverIcons = IconDB.convertFromApiModel(try await SettingsAPI().GetIcons())
        async let serverCurrencies = CurrencyDB.convertFromApiModel(try await SettingsAPI().GetCurrencies())
        async let serverUser = UserDB(try await UserAPI().GetUser())
        async let serverAccountGroups = AccountGroupDB.convertFromApiModel(try await AccountAPI().GetAccountGroups())
        async let serverAccounts = AccountDB.convertFromApiModel(try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo)))
        async let serverTags = TagDB.convertFromApiModel(try await TagAPI().GetTags())
        async let serverTagsToTransactions = TagToTransactionDB.convertFromApiModel(try await TagAPI().GetTagsToTransaction())
        async let serverTransactions = TransactionDB.convertFromApiModel(try await TransactionAPI().GetTransactions(req: GetTransactionReq()))
        
        let localIcons = try await db.getIcons()
        let localCurrencies = try await db.getCurrencies()
        let localUsers = try await db.getUsers()
        let localAccountGroups = try await db.getAccountGroups()
        let localAccounts = try await db.getAccounts()
        let localTags = try await db.getTags()
        let localTagsToTransactions = try await db.getTagsToTransactions()
        let localTransactions = try await db.getTransactions()
        
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
            differences += "\n\nTransactions: \(tagsToTransactionsDifferences)"
            logger.warning("Transactions: \(transactionsDifferences)")
        }
        if differences == "" {
            return nil
        } else {
            return differences
        }
    }
}

// MARK: - Sync
extension Service {
    func sync() async throws {
        logger.info("Синхронизируем данные")
                
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let icons = try await SettingsAPI().GetIcons()
        async let currencies = try await SettingsAPI().GetCurrencies()
        async let user = try await UserAPI().GetUser()
        async let accountGroups = try await AccountAPI().GetAccountGroups()
        async let accounts = try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
        async let tags = try await TagAPI().GetTags()
        async let tagsToTransactions = try await TagAPI().GetTagsToTransaction()
        async let transactions = try await TransactionAPI().GetTransactions(req: GetTransactionReq())
        
        // Удаляем все данные в базе данных
        try await db.deleteAllData()
        
        // Сохраняем данные в базу данных
        logger.info("Сохраняем иконки")
        var iconss = try await icons
//        for (index, icon) in iconss.enumerated() {
//            let iconData = try await SettingsAPI().GetIcon(url: "https://bonavii.com/"+icon.url)
//            let url = URL.documentsDirectory.appending(path: String(icon.url))
//            try iconData.write(to: url, options: [.atomic, .completeFileProtection])
//        }
        try await db.importIcons(IconDB.convertFromApiModel(iconss))
        logger.info("Сохраняем валюты")
        try await db.importCurrencies(CurrencyDB.convertFromApiModel(try await currencies))
        logger.info("Сохраняем пользователя")
        try await db.importUser(UserDB(try await user))
        logger.info("Сохраняем группы счетов")
        try await db.importAccountGroups(AccountGroupDB.convertFromApiModel(try await accountGroups))
        logger.info("Сохраняем счета")
        // Cортируем счета, чтобы сначала были родительские
        let sortedAccountsDB = AccountDB.convertFromApiModel(try await accounts).sorted { l, _ in
            l.isParent
        }
        try await db.importAccounts(sortedAccountsDB)
        logger.info("Сохраняем подкатегории")
        try await db.importTags(TagDB.convertFromApiModel(try await tags))
        logger.info("Сохраняем транзакции")
        try await db.importTransactions(TransactionDB.convertFromApiModel(try await transactions))
        logger.info("Сохраняем связки между подкатегориями и транзакциями")
        try await db.importTagsToTransactions(TagToTransactionDB.convertFromApiModel(try await tagsToTransactions))
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
