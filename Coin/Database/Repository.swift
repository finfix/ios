//
//  Repository.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

// MARK: Writes
extension AppDatabase {
    
    func importIcons(_ icons: [IconDB]) async throws {
        try await dbWriter.write { db in
            for icon in icons {
                try IDMappingDB(localID: icon.id!, serverID: icon.id, modelType: .icon).insert(db)
                try icon.insert(db)
            }
        }
    }
    
    func importCurrencies(_ currencies: [CurrencyDB]) async throws {
        try await dbWriter.write { db in
            for currency in currencies {
                try currency.insert(db)
            }
        }
    }
    
    func importUser(_ user: UserDB) async throws {
        try await dbWriter.write { db in
            try IDMappingDB(localID: user.id!, serverID: user.id, modelType: .user).insert(db)
            try user.insert(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroupDB]) async throws {
        try await dbWriter.write { db in
            for accountGroup in accountGroups {
                try IDMappingDB(localID: accountGroup.id!, serverID: accountGroup.id, modelType: .accountGroup).insert(db)
                try accountGroup.insert(db)
            }
        }
    }
    
    func importAccounts(_ accounts: [AccountDB]) async throws {
        try await dbWriter.write { db in
            for account in accounts {
                try IDMappingDB(localID: account.id!, serverID: account.id, modelType: .account).insert(db)
                try account.insert(db)
            }
        }
    }
    
    func importTags(_ tags: [TagDB]) async throws {
        try await dbWriter.write { db in
            for tag in tags {
                try IDMappingDB(localID: tag.id!, serverID: tag.id, modelType: .tag).insert(db)
                try tag.insert(db)
            }
        }
    }
    
    func importTagsToTransactions(_ tagsToTransactions: [TagToTransactionDB]) async throws {
        try await dbWriter.write { db in
            for tagToTransaction in tagsToTransactions {
                try tagToTransaction.insert(db)
            }
        }
    }
    
    func importTransactions(_ transactions: [TransactionDB]) async throws {
        try await dbWriter.write { db in
            for transaction in transactions {
                try IDMappingDB(localID: transaction.id!, serverID: transaction.id, modelType: .transaction).insert(db)
                try transaction.insert(db)
            }
        }
    }
    
    func deleteAllData() async throws {
        try await dbWriter.write { db in
            _ = try TagToTransactionDB.deleteAll(db)
            _ = try TransactionDB.deleteAll(db)
            _ = try AccountDB.deleteAll(db)
            _ = try TagDB.deleteAll(db)
            _ = try AccountGroupDB.deleteAll(db)
            _ = try UserDB.deleteAll(db)
            _ = try CurrencyDB.deleteAll(db)
            _ = try IconDB.deleteAll(db)
            _ = try IDMappingDB.deleteAll(db)
            _ = try SyncTaskValueDB.deleteAll(db)
            _ = try SyncTaskDB.deleteAll(db)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await dbWriter.write { db in
            _ = try TransactionDB(transaction).delete(db)
        }
    }
    
    func deleteTag(_ tag: Tag) async throws {
        try await dbWriter.write { db in
            _ = try TagDB(tag).delete(db)
        }
    }
    
    func createAccount(_ account: Account) async throws -> UInt32 {
        try await dbWriter.write { db in
            _ = try AccountDB(account).insert(db)
            let id = UInt32(db.lastInsertedRowID)
            try IDMappingDB(localID: id, serverID: nil, modelType: .account)
                .insert(db)
            return id
        }
    }
    
    func createAccountAndReturn(_ account: Account) async throws -> Account {
        try await dbWriter.write { db in
            let account = try AccountDB(account).insertAndFetch(db)
            try IDMappingDB(localID: account!.id!, serverID: nil, modelType: .account)
                .insert(db)
            return Account(account!, currenciesMap: nil, accountGroupsMap: nil, iconsMap: nil)
        }
    }
    
    func updateAccount(_ account: Account) async throws {
        try await dbWriter.write { db in
            _ = try AccountDB(account).update(db)
        }
    }
    
    func updateTag(_ tag: Tag) async throws {
        try await dbWriter.write { db in
            _ = try TagDB(tag).update(db)
        }
    }
    
    func deleteAccount(_ account: Account) async throws {
        try await dbWriter.write { db in
            _ = try AccountDB(account).delete(db)
        }
    }
    
    func updateBalance(id: UInt32, newBalance: Decimal) async throws {
        try await dbWriter.write { db in
            _ = try AccountDB
                .filter(AccountDB.Columns.id == id)
                .updateAll(db, AccountDB.Columns.remainder.set(to: newBalance))
        }
    }
    
    func createTransaction(_ transaction: Transaction) async throws -> UInt32 {
        try await dbWriter.write { db in
            _ = try TransactionDB(transaction).insert(db)
            let id = UInt32(db.lastInsertedRowID)
            try IDMappingDB(localID: id, serverID: nil, modelType: .transaction)
                .insert(db)
            return id
        }
    }
    
    func changeSerialNumbers(accountGroup: AccountGroup, oldValue: UInt32, newValue: UInt32) async throws {
        try await dbWriter.write { db in
            var req = AccountDB.filter(AccountDB.Columns.accountGroupId == accountGroup.id)
            if newValue < oldValue {
                try req
                    .filter(AccountDB.Columns.serialNumber >= newValue && AccountDB.Columns.serialNumber < oldValue)
                    .updateAll(db, AccountDB.Columns.serialNumber += 1)
            } else {
                try req
                    .filter(AccountDB.Columns.serialNumber > oldValue && AccountDB.Columns.serialNumber <= newValue)
                    .updateAll(db, AccountDB.Columns.serialNumber -= 1)
            }
        }
    }
    
    func createTag(_ tag: Tag) async throws -> UInt32 {
        try await dbWriter.write { db in
            _ = try TagDB(tag).insert(db)
            let id = UInt32(db.lastInsertedRowID)
            try IDMappingDB(localID: id, serverID: nil, modelType: .tag)
                .insert(db)
            return id
        }
    }
    
    func linkTagsToTransaction(_ tags: [Tag], transaction: Transaction) async throws {
        try await dbWriter.write { db in
            for tag in tags {
                _ = try TagToTransactionDB(transactionID: transaction.id, tagID: tag.id).insert(db)
            }
        }
    }
    
    func unlinkTagsFromTransaction(_ tags: [Tag], transaction: Transaction) async throws {
        try await dbWriter.write { db in
            for tag in tags {
                _ = try TagToTransactionDB(transactionID: transaction.id, tagID: tag.id).delete(db)
            }
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        try await dbWriter.write { db in
            _ = try TransactionDB(transaction).update(db)
        }
    }
    
    func updateAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await dbWriter.write { db in
            _ = try AccountGroupDB(accountGroup).update(db)
        }
    }
    
    func deleteAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await dbWriter.write { db in
            _ = try AccountGroupDB(accountGroup).delete(db)
        }
    }
    
    func createAccountGroup(_ accountGroup: AccountGroup) async throws -> UInt32 {
        try await dbWriter.write { db in
            _ = try AccountGroupDB(accountGroup).insert(db)
            let id = UInt32(db.lastInsertedRowID)
            try IDMappingDB(localID: id, serverID: nil, modelType: .accountGroup)
                .insert(db)
            return id
        }
    }
}

enum ModelType: String, Codable {
    case account, transaction, tag, icon, user, accountGroup, transactionImage
}

// MARK: - Reads
extension AppDatabase {
    var reader: DatabaseReader {
        dbWriter
    }
    
    func getAvailableIDForAccount() async throws -> UInt32 {
        try await reader.read { db in
            return try Row.fetchOne(db, sql: "SELECT MAX(id) + 1 as max FROM AccountDB")!["max"]
        }
    }
    
    func getCurrencies() async throws -> [CurrencyDB] {
        try await reader.read { db in
            return try CurrencyDB.fetchAll(db).sorted { i, j in
                i.code < j.code
            }
        }
    }
    
    func getUsers() async throws -> [UserDB] {
        try await reader.read { db in
            return try UserDB.fetchAll(db)
        }
    }
    
    func getCountTasks() async throws -> UInt32 {
        try await reader.read { db in
            return UInt32(try SyncTaskDB.fetchCount(db))
        }
    }
    
    func deleteTasks(
        ids: [UInt32]? = nil
    ) async throws {
        try await dbWriter.write { db in
                                    
            var request = SyncTaskDB.filter(SyncTaskDB.Columns.id != 0)
            if let ids {
                request = request.filter(ids.contains(SyncTaskDB.Columns.id))
            }
            
            _ = try request.deleteAll(db)
        }
    }
    
    func getSyncTasks(
        ids: [UInt32]? = nil,
        limit: UInt32? = nil
    ) async throws -> [SyncTask] {
        try await reader.read { db in
            
            var request = SyncTaskDB
                .order(SyncTaskDB.Columns.id)
                .filter(SyncTaskDB.Columns.enabled)
            
            if let limit {
                request = request.limit(Int(limit))
            }
            
            if let ids {
                request = request.filter(ids.contains(SyncTaskDB.Columns.id))
            }
            
            let syncTaskDBs = try request.fetchAll(db)
            
            var syncTasksIDs: [UInt32] = []
            for syncTaskDB in syncTaskDBs {
                syncTasksIDs.append(syncTaskDB.id!)
            }
            
            var questionsArr: [String] = []
            for _ in 0..<syncTaskDBs.count {
                questionsArr.append("?")
            }
                        
            let syncTasksValuesDB = try SyncTaskValueDB
                .fetchAll(db, sql: """
                SELECT
                  tv.id,
                  tv.syncTaskId,
                  tv.objectType,
                  tv.name,
                  CASE WHEN tv.objectType IS NULL
                    THEN tv.value
                    ELSE m.serverID
                  END AS value
                FROM syncTaskValueDB tv
                LEFT JOIN idMappingDB m ON m.localID = tv.value
                  AND m.modelType = tv.objectType
                JOIN syncTaskDB t ON t.id = tv.syncTaskId
                WHERE t.id in (\(questionsArr.joined(separator: ", ")))
            """, arguments: StatementArguments(syncTasksIDs))
                                    
            return SyncTask.convertFromDBModel(
                syncTaskDBs,
                syncTaskValuesMap: SyncTaskValue.groupByTaskID(SyncTaskValue.convertFromDBModel(syncTasksValuesDB))
            )
        }
    }
    
    func getIcons() async throws -> [IconDB] {
        try await reader.read { db in
            return try IconDB.fetchAll(db)
        }
    }
    
    func getAccountGroups() async throws -> [AccountGroupDB] {
        try await reader.read { db in
            return try AccountGroupDB.fetchAll(db).sorted { i, j in
                i.serialNumber < j.serialNumber
            }
        }
    }
    
    func getBalanceForAccount(
        _ account: Account,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) async throws -> Decimal? {
        try await reader.read { db in
            
            var dateFilter = ""
            var args: StatementArguments = ["id": account.id]
            
            if let dateFrom = dateFrom {
                dateFilter += "AND dateTransaction >= :dateFrom"
                _ = args.append(contentsOf: ["dateFrom": dateFrom])
            }
            
            if let dateTo = dateTo {
                dateFilter += "\nAND dateTransaction < :dateTo"
                _ = args.append(contentsOf: ["dateTo": dateTo])
            }
            
            let req = """
                SELECT
                  (
                    SELECT COALESCE(SUM(amountTo),0)
                    FROM transactionDB
                    WHERE accountToId = :id
                    \(dateFilter)
                  ) - (
                    SELECT COALESCE(SUM(amountFrom),0)
                    FROM transactionDB
                    WHERE accountFromId = :id
                    \(dateFilter)
                  ) AS remainder
                """
            
            if let row = try Row.fetchOne(db, sql: req, arguments: args) {
                return row["remainder"]
            }
            return nil
        }
    }
    
    func getTags(
        accountGroupID: UInt32? = nil
    ) async throws -> [TagDB] {
        try await reader.read { db in
            var request = TagDB.order(TagDB.Columns.id)
            if let accountGroupID {
                request = request.filter(TagDB.Columns.accountGroupID == accountGroupID)
            }
            return try request.fetchAll(db)
        }
    }
    
    func getTagsToTransactions() async throws -> [TagToTransactionDB] {
        try await reader.read { db in
            return try TagToTransactionDB.fetchAll(db)
        }
    }
    
    func getAccounts(
        ids: [UInt32]? = nil,
        accountGroupID: UInt32? = nil,
        visible: Bool? = nil,
        accountingInHeader: Bool? = nil,
        types: [AccountType]? = nil,
        currencyCode: String? = nil,
        isParent: Bool? = nil
    ) async throws -> [AccountDB] {
        try await reader.read { db in
            var request = AccountDB
                .order(AccountDB.Columns.serialNumber)
            
            if let ids = ids {
                request = request.filter(keys: ids)
            }
            
            if let accountGroupID = accountGroupID {
                request = request.filter(AccountDB.Columns.accountGroupId == accountGroupID)
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
            
            if let types = types {
                var typesString = [String]()
                for type in types {
                    typesString.append(type.rawValue)
                }
                request = request.filter(typesString.contains(AccountDB.Columns.type))
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getIDsMapping() async throws -> [IDMappingDB] {
        try await reader.read { db in
            return try IDMappingDB.fetchAll(db)
        }
    }
    
    func getTransactions(
        offset: Int = 0,
        limit: Int? = nil,
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UInt32] = [],
        accountGroupID: UInt32? = nil,
        transactionType: TransactionType? = nil,
        currency: Currency? = nil
    ) async throws -> [TransactionDB] {
        try await reader.read { db in
            
            var request = TransactionDB
                .order(TransactionDB.Columns.dateTransaction.desc, TransactionDB.Columns.id.desc)
            
            if let dateFrom {
                request = request.filter(TransactionDB.Columns.dateTransaction >= dateFrom)
            }
            
            if let dateTo {
                request = request.filter(TransactionDB.Columns.dateTransaction <= dateTo)
            }
            
            if searchText != "" {
                request = request.filter(TransactionDB.Columns.note.like("%"+searchText+"%"))
            }
                
            if !accountIDs.isEmpty {
                request = request.filter(accountIDs.contains(TransactionDB.Columns.accountFromId) || accountIDs.contains(TransactionDB.Columns.accountToId))
            }
            
            if let transactionType {
                request = request.filter(TransactionDB.Columns.type == transactionType.rawValue)
            }
            
            if let currency {
                request = request
            }
            
            if let limit {
                request = request.limit(limit, offset: offset)
            }
                    
            return try request.fetchAll(db)
        }
    }
    
    func getStatisticByMonth(
        chartType: ChartType,
        transactionType: TransactionType,
        accountGroupID: UInt32,
        accountParameterIgnore: Bool = false,
        transactionParameterIgnore: Bool = false,
        accountIDs: [UInt32] = []
    ) async throws -> [Series] {
        try await reader.read { db in
            var amountField = ""
            var accountType = ""
            var accountField = ""
            switch transactionType {
            case .consumption:
                amountField = "amountTo"
                accountField = "accountToId"
                accountType = "expense"
            case .income:
                amountField = "amountFrom"
                accountField = "accountFromId"
                accountType = "earnings"
            default:
                return []
            }
            
            var requestParameters: [String] = [
                "a.type = ?",
                "ag.id = ?"
            ]
            var args: StatementArguments = [
                accountType,
                accountGroupID
            ]
            
            if !accountParameterIgnore {
                requestParameters.append("a.accountingInCharts = ?")
                _ = args.append(contentsOf: [true])
            }
            if !transactionParameterIgnore {
                requestParameters.append("t.accountingInCharts = ?")
                _ = args.append(contentsOf: [true])
            }
            if !accountIDs.isEmpty {
                var questions: [String] = []
                for accountID in accountIDs {
                    questions.append("?")
                    _ = args.append(contentsOf: [accountID])
                }
                requestParameters.append("a.id in (\(questions.joined(separator: ", ")))")
            }
            var req: String = ""
            
            switch chartType {
            case .earningsAndExpenses:
                req = """
                    SELECT
                      strftime('%Y-%m-01', t.dateTransaction) AS "month",
                      ROUND(SUM(t.\(amountField) * ((SELECT rate FROM currencyDB WHERE code = ag.currencyCode) / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS remainder
                    FROM transactionDB t
                    JOIN accountDB a ON a.id = t.\(accountField)
                    JOIN accountGroupDB ag  ON a.accountGroupId = ag.id
                    WHERE \(requestParameters.joined(separator: " AND "))
                    GROUP BY "month"
                """
            case .expenses, .earnings:
                var selectAccountStatement = ""
                if accountIDs.isEmpty {
                    selectAccountStatement = """
                          CASE WHEN a.parentAccountId IS NULL
                            THEN a.id
                            ELSE a.parentAccountId
                          END AS accountId,
                    """
                } else {
                    selectAccountStatement = "a.id AS accountId,"
                }
                req = """
                    SELECT
                      strftime('%Y-%m-01', t.dateTransaction) AS "month",
                      \(selectAccountStatement)
                      ROUND(SUM(t.\(amountField) * ((SELECT rate FROM currencyDB WHERE code = ag.currencyCode) / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS remainder
                    FROM transactionDB t
                    JOIN accountDB a ON a.id = t.\(accountField)
                    JOIN accountGroupDB ag  ON a.accountGroupId = ag.id
                    WHERE \(requestParameters.joined(separator: " AND "))
                    GROUP BY "month", "accountId"
                """
            }
                
            var result: [String: [Date: Decimal]] = [:]
            let rows = try Row.fetchCursor(db, sql: req, arguments: args)
            
            var series: [Series] = []
            while let row = try rows.next() {
                switch chartType {
                case .earningsAndExpenses:
                    if result[""] == nil {
                        result[""] = [:]
                    }
                    result[""]?[row["month"]] = row["remainder"]
                case .expenses, .earnings:
                    let accountID: String = row["accountId"]
                    if result[accountID] == nil {
                        result[accountID] = [:]
                    }
                    result[accountID]?[row["month"]] = row["remainder"]
                }
            }
            
            for (categoryName, monthData) in result {
                series.append(Series(
                    account: nil,
                    type: String(categoryName),
                    data: monthData
                ))
            }
                            
            return series
        }
    }
    
    func createTask(_ task: SyncTask) async throws {
        try await dbWriter.write { db in
            _ = try SyncTaskDB(task).insert(db)
            let taskID = db.lastInsertedRowID
            for var field in task.fields {
                field.syncTaskID = UInt32(taskID)
                _ = try SyncTaskValueDB(field).insert(db)
            }
        }
    }
    
    func updateTask(_ task: SyncTask) async throws {
        try await dbWriter.write { db in
            _ = try SyncTaskDB(task).update(db)
        }
    }
    
    func updateServerID(
        localID: UInt32,
        modelType: ModelType,
        serverID: UInt32
    ) async throws {
        try await dbWriter.write { db in
            _ = try IDMappingDB
                .filter(IDMappingDB.Columns.localID == localID && IDMappingDB.Columns.modelType == modelType.rawValue)
                .updateAll(db, IDMappingDB.Columns.serverID.set(to: serverID))
        }
    }
}
