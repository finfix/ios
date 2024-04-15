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
    
    func importCurrencies(_ currencies: [CurrencyDB]) async throws {
        try await dbWriter.write { db in
            for currency in currencies {
                try currency.insert(db)
            }
        }
    }
    
    func importUser(_ user: UserDB) async throws {
        try await dbWriter.write { db in
            try user.insert(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroupDB]) async throws {
        try await dbWriter.write { db in
            for accountGroup in accountGroups {
                try accountGroup.insert(db)
            }
        }
    }
    
    func importAccounts(_ accounts: [AccountDB]) async throws {
        try await dbWriter.write { db in
            for account in accounts {
                try account.insert(db)
            }
        }
    }
    
    func importTransactions(_ transactions: [TransactionDB]) async throws {
        try await dbWriter.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }
    
    func deleteAllData() async throws {
        try await dbWriter.write { db in
            _ = try TransactionDB.deleteAll(db)
            _ = try AccountDB.deleteAll(db)
            _ = try AccountGroupDB.deleteAll(db)
            _ = try UserDB.deleteAll(db)
            _ = try CurrencyDB.deleteAll(db)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await dbWriter.write { db in
            _ = try TransactionDB(transaction).delete(db)
        }
    }
    
    func createAccount(_ account: Account) async throws {
        try await dbWriter.write { db in
            _ = try AccountDB(account).insert(db)
        }
    }
    
    func createAccountAndReturn(_ account: Account) async throws -> AccountDB {
        try await dbWriter.write { db in
            return try AccountDB(account).insertAndFetch(db)!
        }
    }
    
    func updateAccount(_ account: Account) async throws {
        try await dbWriter.write { db in
            _ = try AccountDB(account).update(db)
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
    
    func createTransaction(_ transaction: Transaction) async throws {
        try await dbWriter.write { db in
            _ = try TransactionDB(transaction).insert(db)
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        try await dbWriter.write { db in
            _ = try TransactionDB(transaction).update(db)
        }
    }
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
    
    func getAccounts(
        ids: [UInt32]? = nil,
        accountGroupID: UInt32? = nil,
        visible: Bool? = nil,
        accounting: Bool? = nil,
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
            
            if let accounting = accounting {
                request = request.filter(AccountDB.Columns.accounting == accounting)
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
    
    func getTransactionsWithPagination(
        offset: Int,
        limit: Int,
        accountIDs: [UInt32] = []
    ) async throws -> [TransactionDB] {
        try await reader.read { db in
            
            var request = TransactionDB
                .order(TransactionDB.Columns.dateTransaction.desc, TransactionDB.Columns.id.desc)
                
            if !accountIDs.isEmpty {
                request = request.filter(accountIDs.contains(TransactionDB.Columns.accountFromId) || accountIDs.contains(TransactionDB.Columns.accountToId))
            }
                    
            return try request
                .limit(limit, offset: offset)
                .fetchAll(db)
                
        }
    }
}
