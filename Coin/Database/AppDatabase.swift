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
                table.column("name", .text).notNull()
                table.column("rate", .double).notNull()
                table.column("symbol", .text).notNull()
            }
        }
        
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
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
    
    /// Add all currencies to local database from server
    func importCurrencies(_ currencies: [Currency]) throws {
        try dbWriter.write { db in
            for currency in currencies {
                try currency.save(db)
            }
        }
    }
    
    /// Delete all data of application on device
    func deleteAllData() throws {
        try dbWriter.write { db in
            _ = try Currency.deleteAll(db)
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
}

