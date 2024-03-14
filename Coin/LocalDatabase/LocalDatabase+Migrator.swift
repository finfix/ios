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

//        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
//        #endif

        migrator.registerMigration("v1") { db in
            try createTables(db)
        }

        return migrator

    }

    private func createTables(_ db: GRDB.Database) throws {
        
        try db.create(table: "currencies") { table in
            table.primaryKey("id", .integer)
            table.column("name", .text).notNull()
            table.column("rate", .double).notNull()
            table.column("symbol", .text).notNull()
        }
        
        try db.create(table: "users") { table in
            table.primaryKey("id", .integer)
            table.column("name", .text).notNull()
            table.column("email", .text).notNull()
            table.column("timeCreate", .datetime).notNull()
        }
        
        try db.create(table: "accountGroups") { table in
            table.primaryKey("id", .integer)
            table.column("name", .text).notNull()
            table.column("serialNumber", .integer).notNull()
            
            table.belongsTo("currencyID", inTable: "currency").notNull()
        }
        
        try db.create(table: "accounts") { table in
            table.primaryKey("id", .integer)
            table.column("accounting", .boolean).notNull()
            table.column("iconID", .integer).notNull()
            table.column("name", .text).notNull()
            table.column("remainder", .double).notNull()
            table.column("type", .text).notNull()
            table.column("visible", .bool).notNull()
            table.column("serialNumber", .integer).notNull()
            table.column("isParent", .boolean).notNull()
            table.column("budgetAmount", .double).notNull()
            table.column("budgetFixedSum", .double).notNull()
            table.column("budgetDaysOffset", .integer).notNull()
            table.column("budgetGradualFilling", .boolean).notNull()
            
            table.belongsTo("parentAccountID", inTable: "account")
            table.belongsTo("currency", inTable: "currency").notNull()
            table.belongsTo("accountGroup", inTable: "accountGroups").notNull()
        }
        
        try db.create(table: "transaction") { table in
            table.primaryKey("id", .integer)
            table.column("accounting", .boolean).notNull()
            table.column("amountFrom", .double).notNull()
            table.column("amountTo", .double).notNull()
            table.column("dateTransaction", .date).notNull()
            table.column("isExecuted", .bool).notNull()
            table.column("note", .text)
            table.column("type", .text).notNull()
            table.column("timeCreate", .datetime)
            
            table.belongsTo("accountFrom", inTable: "account").notNull()
            table.belongsTo("accountTo", inTable: "account").notNull()
        }

    }
}
