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
    
    func importCurrencies(_ currencies: [CurrencyDB]) throws {
        try dbWriter.write { db in
            for currency in currencies {
                try currency.insert(db)
            }
        }
    }
    
    func importUser(_ user: UserDB) throws {
        try dbWriter.write { db in
            try user.insert(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroupDB]) throws {
        try dbWriter.write { db in
            for accountGroup in accountGroups {
                try accountGroup.insert(db)
            }
        }
    }
    
    func importAccounts(_ accounts: [AccountDB]) throws {
        try dbWriter.write { db in
            for account in accounts {
                try account.insert(db)
            }
        }
    }
    
    func importTransactions(_ transactions: [TransactionDB]) throws {
        try dbWriter.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }
    
    func deleteAllData() throws {
        try dbWriter.write { db in
            _ = try TransactionDB.deleteAll(db)
            _ = try AccountDB.deleteAll(db)
            _ = try AccountGroupDB.deleteAll(db)
            _ = try UserDB.deleteAll(db)
            _ = try CurrencyDB.deleteAll(db)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) throws {
        try dbWriter.write { db in
            _ = try TransactionDB(transaction).delete(db)
        }
    }
    
    func createAccount(_ account: Account) throws {
        try dbWriter.write { db in
            _ = try AccountDB(account).insert(db)
        }
    }
    
    func updateAccount(_ account: Account) throws {
        try dbWriter.write { db in
            _ = try AccountDB(account).update(db)
        }
    }
    
    func updateBalance(id: UInt32, newBalance: Decimal) throws {
        try dbWriter.write { db in
            _ = try AccountDB
                .filter(Column("id") == id)
                .updateAll(db, Column("remainder").set(to: newBalance))
        }
    }
    
    func createTransaction(_ transaction: Transaction) throws {
        try dbWriter.write { db in
            _ = try TransactionDB(transaction).insert(db)
        }
    }
    
    func updateTransaction(_ transaction: Transaction) throws {
        try dbWriter.write { db in
            _ = try TransactionDB(transaction).update(db)
        }
    }
}

// MARK: - Reads
extension AppDatabase {
    var reader: DatabaseReader {
        dbWriter
    }
    
    func getCurrencies() throws -> [CurrencyDB] {
        try reader.read { db in
            return try CurrencyDB.fetchAll(db).sorted { i, j in
                i.code < j.code
            }
        }
    }
    
    func getAccountGroups() throws -> [AccountGroupDB] {
        try reader.read { db in
            return try AccountGroupDB.fetchAll(db).sorted { i, j in
                i.serialNumber < j.serialNumber
            }
        }
    }
    
    func getBalanceForAccount(
        _ account: Account,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) throws -> Decimal? {
        try reader.read { db in
            
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
        isParent: Bool? = nil
    ) throws -> [AccountDB] {
        try reader.read { db in
            var request = AccountDB
                .order(Column("serialNumber"))
            
            if let ids = ids {
                request = request.filter(keys: ids)
            }
            
            if let accountGroupID = accountGroupID {
                request = request.filter(Column("accountGroupId") == accountGroupID)
            }
            
            if let visible = visible {
                request = request.filter(Column("visible") == visible)
            }
            
            if let accounting = accounting {
                request = request.filter(Column("accounting") == accounting)
            }
            
            if let isParent = isParent {
                request = request.filter(Column("isParent") == isParent)
            }
            
            if let types = types {
                var typesString = [String]()
                for type in types {
                    typesString.append(type.rawValue)
                }
                request = request.filter(typesString.contains(Column("type")))
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getTransactionsWithPagination(offset: Int, limit: Int) throws -> [TransactionDB] {
        try reader.read { db in
            return try TransactionDB
                .order(Column("dateTransaction").desc, Column("id").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
                
        }
    }
}
