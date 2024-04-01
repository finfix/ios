//
//  LocalDatabase+Migrator.swift
//  Coin
//
//  Created by Илья on 14.05.2024.
//

import Foundation
import GRDB

extension LocalDatabase {
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            try createTables(db)
        }

        return migrator

    }

    private func createTables(_ db: GRDB.Database) throws {
        
        try db.create(table: "currency") { table in
            table.primaryKey("code", .text)
            table.column("name", .text).notNull()
            table.column("rate", .double).notNull()
            table.column("symbol", .text).notNull()
        }
//        
        try db.create(table: "user") { table in
            table.primaryKey("id", .integer)
            table.column("name", .text).notNull()
            table.column("email", .text).notNull()
            table.belongsTo("defaultCurrency", inTable: "currency").notNull()
        }
//        
//        try db.create(table: "accountGroup") { table in
//            table.primaryKey("id", .integer)
//            table.column("name", .text).notNull()
//            table.column("serialNumber", .integer).notNull()
//            
//            table.belongsTo("currencyID", inTable: "currency").notNull()
//        }
        
//        try db.create(table: "account") { table in
//            table.primaryKey("id", .integer)
//            table.column("accounting", .boolean).notNull()
//            table.column("iconID", .integer).notNull()
//            table.column("name", .text).notNull()
//            table.column("remainder", .double).notNull()
//            table.column("type", .text).notNull()
//            table.column("visible", .boolean).notNull()
//            table.column("serialNumber", .integer).notNull()
//            table.column("isParent", .boolean).notNull()
//            table.column("budgetAmount", .double).notNull()
//            table.column("budgetFixedSum", .double).notNull()
//            table.column("budgetDaysOffset", .integer).notNull()
//            table.column("budgetGradualFilling", .boolean).notNull()
//            
//            table.belongsTo("parentAccountID", inTable: "account")
//            table.belongsTo("currency", inTable: "currency").notNull()
//            table.belongsTo("accountGroup", inTable: "accountGroups").notNull()
//        }
        
//        try db.create(table: "transaction") { table in
//            table.primaryKey("id", .integer)
//            table.column("accounting", .boolean).notNull()
//            table.column("amountFrom", .double).notNull()
//            table.column("amountTo", .double).notNull()
//            table.column("dateTransaction", .date).notNull()
//            table.column("isExecuted", .boolean).notNull()
//            table.column("note", .text)
//            table.column("type", .text).notNull()
//            table.column("timeCreate", .datetime)
//            
//            table.belongsTo("accountFrom", inTable: "account").notNull()
//            table.belongsTo("accountTo", inTable: "account").notNull()
//        }

    }
}
