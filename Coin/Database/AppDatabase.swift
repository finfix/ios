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
    
    let dbWriter: any DatabaseWriter
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
        
//        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
//        #endif
        
        migrator.registerMigration("createCurrency") { db in
            try db.create(table: "currencyDB") { table in
                
                table.primaryKey("code", .text)
                
                table.column("name", .text)
                    .notNull()
                table.column("rate", .double)
                    .notNull()
                table.column("symbol", .text)
                    .notNull()
            }
            
            try db.create(table: "userDB") { table in
                
                table.primaryKey("id", .integer)
                
                table.column("name", .text)
                    .notNull()
                table.column("email", .double)
                    .notNull()
                
                table.belongsTo("defaultCurrency", inTable: "currencyDB")
                    .notNull()
            }
            
            try db.create(table: "accountGroupDB") { table in
                
                table.primaryKey("id", .integer)
                
                table.column("name", .text)
                    .notNull()
                table.column("serialNumber", .integer)
                    .notNull()
                
                table.belongsTo("currency", inTable: "currencyDB")
                    .notNull()
            }
            
            try db.create(table: "iconDB") { table in
                
                table.primaryKey("id", .integer)
                
                table.column("url", .text)
                    .notNull()
                table.column("name", .text)
                    .notNull()
            }
            
            try db.create(table: "accountDB") { table in
                
                table.primaryKey("id", .integer)
                
                table.column("accountingInHeader", .boolean)
                    .notNull()
                table.column("accountingInCharts", .boolean)
                    .notNull()
                table.column("name", .text)
                    .notNull()
                table.column("remainder", .double)
                    .notNull()
                table.column("type", .text)
                    .notNull()
                table.column("visible", .boolean)
                    .notNull()
                table.column("serialNumber", .integer)
                    .notNull()
                table.column("isParent", .boolean)
                    .notNull()
                table.column("budgetAmount", .double)
                    .notNull()
                table.column("budgetFixedSum", .double)
                    .notNull()
                table.column("budgetDaysOffset", .integer)
                    .notNull()
                table.column("budgetGradualFilling", .boolean)
                    .notNull()
                table.column("datetimeCreate", .date)
                    .notNull()
                
                table.belongsTo("icon", inTable: "iconDB")
                    .notNull()
                table.belongsTo("parentAccount", inTable: "accountDB")
                table.belongsTo("accountGroup", inTable: "accountGroupDB")
                    .notNull()
                table.belongsTo("currency", inTable: "currencyDB")
                    .notNull()
            }
            
            try db.create(table: "transactionDB") { table in
                
                table.primaryKey("id", .integer)
                
                table.column("accounting", .boolean)
                    .notNull()
                table.column("amountFrom", .double)
                    .notNull()
                table.column("amountTo", .double)
                    .notNull()
                table.column("dateTransaction", .date)
                    .notNull()
                table.column("isExecuted", .double)
                    .notNull()
                table.column("note", .text)
                    .notNull()
                table.column("datetimeCreate", .date)
                    .notNull()
                table.column("type", .text)
                    .notNull()
                
                table.belongsTo("accountFrom", inTable: "accountDB")
                    .notNull()
                table.belongsTo("accountTo", inTable: "accountDB")
                    .notNull()
            }
            
            try db.create(table: "tagDB") { table in
                
                table.primaryKey("id", .integer)
                
                table.column("name", .text)
                    .notNull()
                table.column("datetimeCreate", .date)
                    .notNull()
                
                table.belongsTo("accountGroup", inTable: "accountGroupDB")
                    .notNull()
            }
            
            try db.create(table: "tagToTransactionDB") { table in
                
                table.belongsTo("tag", inTable: "tagDB")
                table.belongsTo("transaction", inTable: "transactionDB")
                
                table.primaryKey(["tagId", "transactionId"])
            }
        }
        
        return migrator
    }
}
