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
            _ = try CurrencyDB.deleteAll(db)
            _ = try UserDB.deleteAll(db)
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
}
