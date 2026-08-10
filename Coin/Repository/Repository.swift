//
//  Repository.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

class Repository {
    
    init(sqlite: SQLite) {
        self.sqlite = sqlite
    }
    
    private let sqlite: SQLite
    
    func importIcons(_ icons: [IconDB]) async throws {
        try await sqlite.write { db in
            for icon in icons {
                try icon.insert(db)
            }
        }
    }
    
    func importCurrencies(_ currencies: [CurrencyDB]) async throws {
        try await sqlite.write { db in
            for currency in currencies {
                try currency.insert(db)
            }
        }
    }
    
    func importUser(_ user: UserDB) async throws {
        try await sqlite.write { db in
            try user.insert(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroupDB]) async throws {
        try await sqlite.write { db in
            for accountGroup in accountGroups {
                try accountGroup.insert(db)
            }
        }
    }
    
    func importAccounts(_ accounts: [AccountDB]) async throws {
        try await sqlite.write { db in
            for account in accounts {
                try account.insert(db)
            }
        }
    }
    
    func importTags(_ tags: [TagDB]) async throws {
        try await sqlite.write { db in
            for tag in tags {
                try tag.insert(db)
            }
        }
    }
    
    func importTagsToTransactions(_ tagsToTransactions: [TagToTransactionDB]) async throws {
        try await sqlite.write { db in
            for tagToTransaction in tagsToTransactions {
                try tagToTransaction.insert(db)
            }
        }
    }
    
    func importTransactions(_ transactions: [TransactionDB]) async throws {
        try await sqlite.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }
    
    func deleteAllData() async throws {
        try await sqlite.write { db in
            _ = try TagToTransactionDB.deleteAll(db)
            _ = try TransactionDB.deleteAll(db)
            _ = try AccountDB.deleteAll(db)
            _ = try TagDB.deleteAll(db)
            _ = try AccountGroupDB.deleteAll(db)
            _ = try UserDB.deleteAll(db)
            _ = try CurrencyDB.deleteAll(db)
            _ = try IconDB.deleteAll(db)
            _ = try SyncTaskDB.deleteAll(db)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await sqlite.write { db in
            _ = try TransactionDB(transaction).delete(db)
        }
    }
    
    func deleteTag(_ tag: Tag) async throws {
        try await sqlite.write { db in
            _ = try TagDB(tag).delete(db)
        }
    }
    
    func createAccount(_ account: Account) async throws {
        try await sqlite.write { db in
            try AccountDB(account).insert(db)
        }
    }
    
    
    func updateAccount(_ account: Account) async throws {
        try await sqlite.write { db in
            _ = try AccountDB(account).update(db)
        }
    }
    
    func updateTag(_ tag: Tag) async throws {
        try await sqlite.write { db in
            _ = try TagDB(tag).update(db)
        }
    }
    
    func updateUser(_ user: User) async throws {
        try await sqlite.write { db in
            _ = try UserDB(user).update(db)
        }
    }
    
    func deleteAccount(_ account: Account) async throws {
        try await sqlite.write { db in
            _ = try AccountDB(account).delete(db)
        }
    }
    
    func updateBalance(id: UUID, newBalance: Decimal) async throws {
        try await sqlite.write { db in
            
            let sql = """
                UPDATE accountDB
                SET remainder = CASE
                                 WHEN type = 'earnings' THEN ? * -1
                                 ELSE ?
                              END
                WHERE id = ?;
            """
            _ = try db.execute(sql: sql, arguments: [newBalance, newBalance, id])
        }
    }
    
    func createTransaction(_ transaction: Transaction) async throws {
        try await sqlite.write { db in
            try TransactionDB(transaction).insert(db)
        }
    }
    
    func createTag(_ tag: Tag) async throws {
        try await sqlite.write { db in
            try TagDB(tag).insert(db)
        }
    }
    
    func linkTagsToTransaction(_ tags: [Tag], transaction: Transaction) async throws {
        try await sqlite.write { db in
            for tag in tags {
                _ = try TagToTransactionDB(transactionID: transaction.id, tagID: tag.id).insert(db)
            }
        }
    }
    
    func unlinkTagsFromTransaction(_ tags: [Tag], transaction: Transaction) async throws {
        try await sqlite.write { db in
            for tag in tags {
                _ = try TagToTransactionDB(transactionID: transaction.id, tagID: tag.id).delete(db)
            }
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        try await sqlite.write { db in
            _ = try TransactionDB(transaction).update(db)
        }
    }
    
    func updateAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await sqlite.write { db in
            _ = try AccountGroupDB(accountGroup).update(db)
        }
    }
    
    func deleteAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await sqlite.write { db in
            _ = try AccountGroupDB(accountGroup).delete(db)
        }
    }
    
    func createAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await sqlite.write { db in
            try AccountGroupDB(accountGroup).insert(db)
        }
    }

    
    func getAvailableIDForAccount() async throws -> UInt32 {
        try await sqlite.read { db in
            return try Row.fetchOne(db, sql: "SELECT MAX(id) + 1 as max FROM AccountDB")!["max"]
        }
    }
    
    func getCurrencies(searchText: String = "") async throws -> [CurrencyDB] {
        try await sqlite.read { db in
            
            var request = CurrencyDB.order(CurrencyDB.Columns.code)
            
            if !searchText.isEmpty {
                request = request.filter(CurrencyDB.Columns.code.like("%"+searchText+"%") || CurrencyDB.Columns.name.like("%"+searchText+"%"))
            }

            return try request.fetchAll(db)
        }
    }
    
    func getUsers() async throws -> [UserDB] {
        try await sqlite.read { db in
            return try UserDB.fetchAll(db)
        }
    }
    
    // Считает только невыполненные таски — используется как гейт перед операциями,
    // которым нужно дождаться окончания фоновой синхронизации (см. compareLocalAndServerData).
    func getCountTasks() async throws -> UInt32 {
        try await sqlite.read { db in
            return UInt32(try SyncTaskDB.filter(!SyncTaskDB.Columns.completed).fetchCount(db))
        }
    }

    // Помечает таски выполненными вместо физического удаления — так их можно показать
    // в списке по переключателю "Показать выполненные" вместо безвозвратной потери истории.
    func completeTasks(
        ids: [UUID]? = nil
    ) async throws {
        try await sqlite.write { db in

            var request = SyncTaskDB.filter(SyncTaskDB.Columns.id != 0)
            if let ids {
                request = request.filter(ids.contains(SyncTaskDB.Columns.id))
            }

            _ = try request.updateAll(db, SyncTaskDB.Columns.completed.set(to: true))
        }
    }

    func getSyncTasks(
        ids: [UUID]? = nil,
        limit: UInt32? = nil,
        includeCompleted: Bool = false
    ) async throws -> [SyncTask] {
        try await sqlite.read { db in

            var request = SyncTaskDB
                .order(SyncTaskDB.Columns.datetimeCreate)

            if !includeCompleted {
                request = request.filter(!SyncTaskDB.Columns.completed)
            }

            if let limit {
                request = request.limit(Int(limit))
            }

            if let ids {
                request = request.filter(ids.contains(SyncTaskDB.Columns.id))
            }
            
            let syncTaskDBs = try request.fetchAll(db)
            
            var syncTasksIDs: [UUID] = []
            for syncTaskDB in syncTaskDBs {
                syncTasksIDs.append(syncTaskDB.id!)
            }
            
            var questionsArr: [String] = []
            for _ in 0..<syncTaskDBs.count {
                questionsArr.append("?")
            }
                                    
            return try SyncTask.convertFromDBModel(syncTaskDBs)
        }
    }
    
    func getIcons() async throws -> [IconDB] {
        try await sqlite.read { db in
            return try IconDB.fetchAll(db)
        }
    }
    
    func getAccountGroups(
        name: String? = nil
    ) async throws -> [AccountGroupDB] {
        try await sqlite.read { db in
            
            var request = AccountGroupDB.order(AccountGroupDB.Columns.serialNumber)
            
            if let name {
                request = request.filter(AccountGroupDB.Columns.name.like("%"+name+"%"))
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getBalances(
        accountIDs: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        accountTypes: [AccountType] = [],
        accountGroupIDs: [UUID] = []
    ) async throws -> [UUID: Decimal] {
        try await sqlite.read { db in
            
            if accountIDs.isEmpty && accountTypes.isEmpty && accountGroupIDs.isEmpty {
                return [:]
            }
            
            var dateFilter = ""
            var filters: [String] = []
            var joins: [String] = []
            var args: StatementArguments = []
            var accountsJoined = false
            
            if let dateFrom = dateFrom {
                dateFilter += "AND dateTransaction >= ?"
                _ = args.append(contentsOf: [dateFrom])
            }
            
            if let dateTo = dateTo {
                dateFilter += "\nAND dateTransaction < ?"
                _ = args.append(contentsOf: [dateTo])
            }
            
            if let dateFrom = dateFrom {
                _ = args.append(contentsOf: [dateFrom])
            }
            
            if let dateTo = dateTo {
                _ = args.append(contentsOf: [dateTo])
            }
            
            if !accountTypes.isEmpty {
                var qs: [String] = []
                for _ in accountTypes {
                    qs.append("?")
                }
                joins.append("JOIN accountDB a ON a.Id = t.accountId")
                accountsJoined = true
                filters.append("a.type in (\(qs.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountTypes.map(\.rawValue)))
            }
            
            if !accountIDs.isEmpty {
                var qs: [String] = []
                for _ in accountIDs {
                    qs.append("?")
                }
                if !accountsJoined {
                    joins.append("JOIN accountDB a ON a.id = t.accountId")
                }
                filters.append("a.id in (\(qs.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }
            
            if !accountGroupIDs.isEmpty {
                var qs: [String] = []
                for _ in accountIDs {
                    qs.append("?")
                }
                if !accountsJoined {
                    joins.append("JOIN accountDB a ON a.id = t.accountId")
                }
                filters.append("a.accountGroupId in (\(qs.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
            }
            
            let req = """
                SELECT 
                    accountId,
                    (
                        SELECT COALESCE(SUM(amountTo), 0)
                        FROM transactionDB
                        WHERE accountToId = t.accountId
                        \(dateFilter)
                    ) - (
                        SELECT COALESCE(SUM(amountFrom), 0)
                        FROM transactionDB
                        WHERE accountFromId = t.accountId
                        \(dateFilter)
                    ) AS remainder
                FROM (
                    SELECT DISTINCT accountToId AS accountId FROM transactionDB
                    UNION
                    SELECT DISTINCT accountFromId AS accountId FROM transactionDB
                ) AS t
                \(joins.joined(separator: "\n"))
                \(!filters.isEmpty ? "WHERE \(filters.joined(separator: "\nAND"))" : "")
                """
            
            var accountBalances: [UUID: Decimal] = [:]
            
            print(req)
            print(args)
            let rows = try Row.fetchCursor(db, sql: req, arguments: args)
            while let row = try rows.next() {
                accountBalances[row["accountId"]] = row["remainder"]
            }
            
            return accountBalances
        }
    }
    
    func getTags(
        accountGroupID: UUID? = nil,
        name: String? = nil
    ) async throws -> [TagDB] {
        try await sqlite.read { db in
            var request = TagDB.order(TagDB.Columns.id)
            if let accountGroupID {
                request = request.filter(TagDB.Columns.accountGroupID == accountGroupID)
            }
            if let name {
                request = request.filter(TagDB.Columns.name.like("%"+name+"%"))
            }
            return try request.fetchAll(db)
        }
    }
    
    func getTagsToTransactions() async throws -> [TagToTransactionDB] {
        try await sqlite.read { db in
            return try TagToTransactionDB.fetchAll(db)
        }
    }
    
    func getAccounts(
        ids: [UUID]? = nil,
        accountGroupIDs: [UUID]? = nil,
        visible: Bool? = nil,
        accountingInHeader: Bool? = nil,
        types: [AccountType]? = nil,
        currencyCode: String? = nil,
        isParent: Bool? = nil,
        name: String? = nil
    ) async throws -> [AccountDB] {
        try await sqlite.read { db in
            var request = AccountDB
                .order(AccountDB.Columns.rank)
            
            if let ids = ids {
                request = request.filter(keys: ids)
            }
            
            if let accountGroupIDs {
                request = request.filter(accountGroupIDs.contains(AccountDB.Columns.accountGroupId))
            }
            
            if let visible = visible {
                request = request.filter(AccountDB.Columns.visible == visible)
            }
            
            if let accountingInHeader = accountingInHeader {
                request = request.filter(AccountDB.Columns.accountingInHeader == accountingInHeader)
            }
            
            if let currencyCode = currencyCode {
                request = request.filter(AccountDB.Columns.currencyCode == currencyCode)
            }
            
            if let isParent = isParent {
                request = request.filter(AccountDB.Columns.isParent == isParent)
            }
            
            if let name = name {
                request = request.filter(AccountDB.Columns.name.like("%"+name+"%"))
            }
            
            if let types = types {
                request = request.filter(types.map(\.rawValue).contains(AccountDB.Columns.type))
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getTransactions(
        limit: Int = 100,
        offset: Int = 0,
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        accountGroupIDs: [UUID] = [],
        transactionTypes: [TransactionType] = [],
        currencies: [Currency] = [],
        tagIDs: [UUID] = []
    ) async throws -> [TransactionDB] {
        try await sqlite.read { db in

            var joins: [String] = []
            var filters: [String] = []
            var args: StatementArguments = []

            if let dateFrom {
                filters.append("t.dateTransaction >= ?")
                _ = args.append(contentsOf: [dateFrom])
            }

            if let dateTo {
                filters.append("t.dateTransaction <= ?")
                _ = args.append(contentsOf: [dateTo])
            }

            if searchText != "" {
                filters.append("t.note LIKE ?")
                _ = args.append(contentsOf: ["%"+searchText+"%"])
            }

            if !accountIDs.isEmpty {

                var questions: [String] = []
                for _ in accountIDs {
                    questions.append("?")
                }

                filters.append("(t.accountFromId IN (\(questions.joined(separator: ","))) OR t.accountToId IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }

            if !excludedAccountIDs.isEmpty {

                var questions: [String] = []
                for _ in excludedAccountIDs {
                    questions.append("?")
                }

                filters.append("(t.accountFromId NOT IN (\(questions.joined(separator: ","))) AND t.accountToId NOT IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
            }

            if !accountGroupIDs.isEmpty {
                
                var questions: [String] = []
                for _ in accountGroupIDs {
                    questions.append("?")
                }
                
                filters.append("t.accountGroupId IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
            }
            
            if !tagIDs.isEmpty {
                
                var questions: [String] = []
                for _ in tagIDs {
                    questions.append("?")
                }
                
                joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")
                
                filters.append("tg.id IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(tagIDs))
            }
            
            if !transactionTypes.isEmpty {
                var questions: [String] = []
                for _ in transactionTypes {
                    questions.append("?")
                }
                
                filters.append("t.type IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(transactionTypes.map(\.rawValue)))
            }
            
            if !currencies.isEmpty {
                var questions: [String] = []
                for _ in transactionTypes {
                    questions.append("?")
                }
                
                joins.append("JOIN accountDB a1 ON a1.id = t.accountFromId")
                joins.append("JOIN accountDB a2 ON a2.id = t.accountToId")

                filters.append("(a1.currency IN (\(questions.joined(separator: ","))) OR a2.currency IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(transactionTypes.map(\.rawValue)))
                _ = args.append(contentsOf: StatementArguments(transactionTypes.map(\.rawValue)))
            }
                        
            let sql = """
                SELECT *
                FROM transactionDB t
                \(joins.joined(separator: "\n"))
                \(filters.isEmpty ? "" : "WHERE \(filters.joined(separator: "\nAND "))")
                ORDER BY t.dateTransaction DESC, t.datetimeCreate DESC
                LIMIT \(limit) OFFSET \(offset)
            """
            
            print(sql)
            print(args)
                    
            return try TransactionDB.fetchAll(db, sql: sql, arguments: args)
        }
    }
    
    func getStatisticByMonth(
        chartType: ChartType,
        groupBy: ChartViewGroupBy,
        period: ChartPeriod = .month,
        transactionType: TransactionType,
        accountGroupIDs: [UUID],
        targetCurrency: Currency,
        accountParameterIgnore: Bool = false,
        transactionParameterIgnore: Bool = false,
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        tagIDs: [UUID] = []
    ) async throws -> [Series] {
        try await sqlite.read { db in
            
            var selects: [String] = [
                "\(period.sqlStartOf("t.dateTransaction")) AS month",
                "ROUND(SUM(t.\(transactionType == .consumption ? "amountTo" : "amountFrom") * ((SELECT rate FROM currencyDB WHERE code = '\(targetCurrency.code)') / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS remainder"
            ]
            var joins: [String] = [
                "JOIN accountDB a ON a.id = t.\(transactionType == .consumption ? "accountToId" : "accountFromId")"
            ]
            var filters: [String] = [
                "a.type = ?"
            ]
            var args: StatementArguments = [
                "\(transactionType == .consumption ? "expense" : "earnings")"
            ]
            var groups: [String] = [
                "month"
            ]
                       
            var tagJoined = false
            if chartType == .expenses || chartType == .earnings {
                switch groupBy {
                case .byAccount:
                    selects.append("a.id AS accountId")
                    groups.append("accountId")
                case .byTag:
                    selects.append("tg.id as tagId")
                    joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                    joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")
                    groups.append("tagId")
                    tagJoined = true
                }
            }

            // Опциональные фильтры
            if !accountParameterIgnore {
                filters.append("a.accountingInCharts = ?")
                _ = args.append(contentsOf: [true])
            }
            if !transactionParameterIgnore {
                filters.append("t.accountingInCharts = ?")
                _ = args.append(contentsOf: [true])
            }
            if !accountIDs.isEmpty {
                var questions: [String] = []
                for _ in accountIDs {
                    questions.append("?")
                }
                filters.append("a.id in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }
            if !excludedAccountIDs.isEmpty {
                var questions: [String] = []
                for _ in excludedAccountIDs {
                    questions.append("?")
                }
                filters.append("a.id not in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
            }
            if !accountGroupIDs.isEmpty {
                var questions: [String] = []
                for accountGroupID in accountGroupIDs {
                    questions.append("?")
                    _ = args.append(contentsOf: [accountGroupID])
                }
                filters.append("t.accountGroupId in (\(questions.joined(separator: ", ")))")
            }
            if let dateFrom {
                filters.append("t.dateTransaction >= ?")
                _ = args.append(contentsOf: [dateFrom])
            }
            if let dateTo {
                filters.append("t.dateTransaction <= ?")
                _ = args.append(contentsOf: [dateTo])
            }
            if !tagIDs.isEmpty {
                var questions: [String] = []
                for _ in tagIDs {
                    questions.append("?")
                }
                if !tagJoined {
                    joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                    joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")
                }
                filters.append("tg.id in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(tagIDs))
            }
                            
            // Мапа ObjectID - Дата - Сумма
            var result: [UUID: [Date: Decimal]] = [:]
            
            let sql = """
                SELECT \(selects.joined(separator: ",\n"))
                FROM transactionDB t
                \(joins.joined(separator: "\n"))
                WHERE \(filters.joined(separator: "\nAND "))
                GROUP BY \(groups.joined(separator: ", "))
            """
            
            print(sql)
            print(args)
            
            let rows = try Row.fetchCursor(db, sql: sql, arguments: args)
            
            while let row = try rows.next() {
                switch chartType {
                case .earningsAndExpenses:
                    if result[UUID(uuid: UUID_NULL)] == nil {
                        result[UUID(uuid: UUID_NULL)] = [:]
                    }
                    result[UUID(uuid: UUID_NULL)]?[row["month"]] = row["remainder"]
                case .expenses, .earnings:
                    switch groupBy {
                    case .byTag:
                        let tagID: UUID = row["tagId"]
                        if result[tagID] == nil {
                            result[tagID] = [:]
                        }
                        result[tagID]?[row["month"]] = row["remainder"]
                    case .byAccount:
                        let accountID: UUID = row["accountId"]
                        if result[accountID] == nil {
                            result[accountID] = [:]
                        }
                        result[accountID]?[row["month"]] = row["remainder"]
                    }
                case .balance, .balanceTotal, .delta:
                    break // Баланс обрабатывается отдельно через getMonthlyNetFlowByAccount; дельта сюда не заходит (передаётся .earningsAndExpenses)
                }
            }
            
            return result.map { (categoryName: UUID, monthData: [Date : Decimal]) in
                Series(
                    account: nil,
                    tag: nil,
                    type: nil,
                    objectID: categoryName,
                    data: monthData
                )
            }
        }
    }
    
    // Возвращает чистый поток по периодам для счетов типа regular/debt
    // Положительное значение = деньги поступили, отрицательное = ушли
    func getMonthlyNetFlowByAccount(
        period: ChartPeriod = .month,
        targetCurrency: Currency,
        accountGroupIDs: [UUID] = [],
        accountIDs: [UUID] = []
    ) async throws -> [UUID: [Date: Decimal]] {
        try await sqlite.read { db in
            var result: [UUID: [Date: Decimal]] = [:]
            
            // Строим фильтры общие для обоих запросов
            func buildFiltersAndArgs(accountIDField: String) -> ([String], StatementArguments) {
                var filters: [String] = [
                    "a.type IN ('regular', 'debt')",
                    "a.accountingInCharts = 1",
                    "t.accountingInCharts = 1"
                ]
                var args: StatementArguments = []
                if !accountIDs.isEmpty {
                    let q = accountIDs.map { _ in "?" }.joined(separator: ", ")
                    filters.append("a.id IN (\(q))")
                    _ = args.append(contentsOf: StatementArguments(accountIDs))
                }
                if !accountGroupIDs.isEmpty {
                    let q = accountGroupIDs.map { _ in "?" }.joined(separator: ", ")
                    filters.append("t.accountGroupId IN (\(q))")
                    _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
                }
                return (filters, args)
            }
            
            let periodExpr = period.sqlStartOf("t.dateTransaction")
            
            // Деньги, поступающие на счёт (accountToId)
            let (inFilters, inArgs) = buildFiltersAndArgs(accountIDField: "accountToId")
            let inSQL = """
                SELECT \(periodExpr) AS month,
                    a.id AS accountId,
                    ROUND(SUM(t.amountTo * ((SELECT rate FROM currencyDB WHERE code = '\(targetCurrency.code)') / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS amount
                FROM transactionDB t
                JOIN accountDB a ON a.id = t.accountToId
                WHERE \(inFilters.joined(separator: " AND "))
                GROUP BY month, accountId
            """
            let inRows = try Row.fetchCursor(db, sql: inSQL, arguments: inArgs)
            while let row = try inRows.next() {
                let accountID: UUID = row["accountId"]
                let month: Date = row["month"]
                let amount: Decimal = row["amount"]
                if result[accountID] == nil { result[accountID] = [:] }
                result[accountID]![month, default: 0] += amount
            }
            
            // Деньги, уходящие со счёта (accountFromId)
            let (outFilters, outArgs) = buildFiltersAndArgs(accountIDField: "accountFromId")
            let outSQL = """
                SELECT \(periodExpr) AS month,
                    a.id AS accountId,
                    ROUND(SUM(t.amountFrom * ((SELECT rate FROM currencyDB WHERE code = '\(targetCurrency.code)') / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS amount
                FROM transactionDB t
                JOIN accountDB a ON a.id = t.accountFromId
                WHERE \(outFilters.joined(separator: " AND "))
                GROUP BY month, accountId
            """
            let outRows = try Row.fetchCursor(db, sql: outSQL, arguments: outArgs)
            while let row = try outRows.next() {
                let accountID: UUID = row["accountId"]
                let month: Date = row["month"]
                let amount: Decimal = row["amount"]
                if result[accountID] == nil { result[accountID] = [:] }
                result[accountID]![month, default: 0] -= amount
            }
            
            return result
        }
    }
    
    func createTask(_ task: SyncTask) async throws {
        try await sqlite.write { db in
            try SyncTaskDB(task).insert(db)
        }
    }
    
    func updateTask(_ task: SyncTask) async throws {
        try await sqlite.write { db in
            _ = try SyncTaskDB(task).update(db)
        }
    }
}

enum ModelType: String, Codable {
    case account, transaction, tag, icon, user, accountGroup
}
