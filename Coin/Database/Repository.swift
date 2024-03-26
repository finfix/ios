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
                try currency.save(db)
            }
        }
    }
    
    func importUser(_ user: UserDB) throws {
        try dbWriter.write { db in
            try user.save(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroupDB]) throws {
        try dbWriter.write { db in
            for accountGroup in accountGroups {
                try accountGroup.save(db)
            }
        }
    }
    
    func importAccounts(_ accounts: [AccountDB]) throws {
        try dbWriter.write { db in
            for account in accounts {
                try account.save(db)
            }
        }
    }
    
    func importTransactions(_ transactions: [TransactionDB]) throws {
        try dbWriter.write { db in
            for transaction in transactions {
                try transaction.save(db)
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
    
    func deleteTransactionAndChangeBalances(_ transaction: Transaction) throws {
        try dbWriter.write { db in
            _ = try TransactionDB(transaction).delete(db)
            _ = try AccountDB(transaction.accountFrom).update(db)
            _ = try AccountDB(transaction.accountTo).update(db)
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
    
    func getAccounts(
        ids: [UInt32]? = nil
    ) throws -> [AccountDB] {
        try reader.read { db in
            var request = AccountDB
                .order(Column("serialNumber"))
            
            if let ids = ids {
                request = request.filter(keys: ids)
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getTransactionsWithPagination(offset: Int, limit: Int) throws -> [TransactionDB] {
        try reader.read { db in
            return try TransactionDB
                .order(Column("dateTransaction").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
                
        }
    }
}
