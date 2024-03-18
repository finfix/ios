//
//  AppDatabase.swift
//  Coin
//
//  Created by Илья on 16.03.2024.
//

import Foundation
import GRDB
import os.log

struct AppDatabase {
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    private let dbWriter: any DatabaseWriter
}

// MARK: - Database Configuration

extension AppDatabase {
    private static let sqlLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SQL")
    
    public static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base
                
        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace {
                    os_log("%{public}@", log: sqlLogger, type: .debug, String(describing: $0))
                }
            }
        }
        
        #if DEBUG
        config.publicStatementArguments = true
        #endif
        
        return config
    }
}

// MARK: - Database Migrations

extension AppDatabase {
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        migrator.registerMigration("createCurrency") { db in
            try db.create(table: "currency") { table in
                table.primaryKey("code", .text)
                
                table.column("name", .text)
                    .notNull()
                    .unique()
                table.column("rate", .double)
                    .notNull()
                table.column("symbol", .text)
                    .notNull()
            }
        }
        
        migrator.registerMigration("createUser") { db in
            try db.create(table: "user") { table in
                table.primaryKey("id", .integer)
                
                table.column("name", .text)
                    .notNull()
                table.column("email", .double)
                    .notNull()
                    .unique()
                
                table.belongsTo("defaultCurrency", inTable: "currency")
                    .notNull()
            }
        }
        
        migrator.registerMigration("createAccountGroup") { db in
            try db.create(table: "accountGroup") { table in
                table.primaryKey("id", .integer)
                
                table.column("name", .text)
                    .notNull()
                table.column("serialNumber", .integer)
                    .notNull()
                
                table.belongsTo("currency", inTable: "currency")
                    .notNull()
            }
        }
        
        return migrator
    }
}

// MARK: - Database Access: Writes
extension AppDatabase {
    
//    /// A validation error that prevents some players from being saved into
//    /// the database.
//    enum ValidationError: LocalizedError {
//        case missingName
//        
//        var errorDescription: String? {
//            switch self {
//            case .missingName:
//                return "Please provide a name"
//            }
//        }
//    }
    
// MARK: - imports
    func importCurrencies(_ currencies: [Currency]) throws {
        try dbWriter.write { db in
            for currency in currencies {
                try currency.save(db)
            }
        }
    }
    
    func importUser(_ user: User) throws {
        try dbWriter.write { db in
            try user.save(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroup]) throws {
        try dbWriter.write { db in
            for accountGroup in accountGroups {
                try accountGroup.save(db)
            }
        }
    }
    
// MARK: - deletes
    func deleteAllData() throws {
        try dbWriter.write { db in
            _ = try Currency.deleteAll(db)
            _ = try User.deleteAll(db)
        }
    }
}

// MARK: - Database Access: Reads

// This demo app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader {
        dbWriter
    }
    
    func getCurrencyForUser(_ user: User) async throws -> Currency {
        try await reader.read { db in
            return try user.currency.fetchOne(db)!
        }
    }
}

