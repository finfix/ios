//
//  Migrator.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import GRDB

extension SQLite {
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
//#if DEV
//        migrator.eraseDatabaseOnSchemaChange = true
//#endif
        
        migrator.registerMigration("createCurrency") { db in
            try db.create(table: "currencyDB") { table in
                
                table.primaryKey("code", .text)
                
                table.column("name", .text)
                    .notNull()
                table.column("rate", .text)
                    .notNull()
                table.column("symbol", .text)
                    .notNull()
            }
            
            try db.create(table: "userDB") { table in
                
                
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text)
                    .notNull()
                table.column("email", .text)
                    .notNull()
                
                table.belongsTo("defaultCurrency", inTable: "currencyDB")
                    .notNull()
            }
            
            try db.create(table: "accountGroupDB") { table in
                
                
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text)
                    .notNull()
                table.column("serialNumber", .integer)
                    .notNull()
                
                table.belongsTo("currency", inTable: "currencyDB")
                    .notNull()
            }
            
            try db.create(table: "iconDB") { table in
                
                
                table.autoIncrementedPrimaryKey("id")
                table.column("url", .text)
                    .notNull()
                table.column("name", .text)
                    .notNull()
            }
            
            try db.create(table: "accountDB") { table in
                
                
                table.autoIncrementedPrimaryKey("id")
                table.column("accountingInHeader", .boolean)
                    .notNull()
                table.column("accountingInCharts", .boolean)
                    .notNull()
                table.column("name", .text)
                    .notNull()
                table.column("remainder", .text)
                    .notNull()
                table.column("type", .text)
                    .notNull()
                table.column("visible", .boolean)
                    .notNull()
                table.column("serialNumber", .integer)
                    .notNull()
                table.column("isParent", .boolean)
                    .notNull()
                table.column("budgetAmount", .text)
                    .notNull()
                table.column("budgetFixedSum", .text)
                    .notNull()
                table.column("budgetDaysOffset", .integer)
                    .notNull()
                table.column("budgetGradualFilling", .boolean)
                    .notNull()
                table.column("datetimeCreate", .datetime)
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
                
                
                table.autoIncrementedPrimaryKey("id")
                table.column("accounting", .boolean)
                    .notNull()
                table.column("amountFrom", .text)
                    .notNull()
                table.column("amountTo", .text)
                    .notNull()
                table.column("dateTransaction", .date)
                    .notNull()
                table.column("isExecuted", .boolean)
                    .notNull()
                table.column("note", .text)
                    .notNull()
                table.column("datetimeCreate", .datetime)
                    .notNull()
                table.column("type", .text)
                    .notNull()
                
                table.belongsTo("accountFrom", inTable: "accountDB")
                    .notNull()
                table.belongsTo("accountTo", inTable: "accountDB")
                    .notNull()
            }
            
            try db.create(table: "tagDB") { table in
                
                
                table.autoIncrementedPrimaryKey("id")
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
            
            try db.create(table: "syncTaskDB") { table in
                
                table.autoIncrementedPrimaryKey("id")
                
                table.column("localID", .integer)
                    .notNull()
                table.column("actionName", .text)
                    .notNull()
                table.column("tryCount", .integer)
                    .notNull()
                table.column("enabled", .boolean)
                    .notNull()
                table.column("error", .text)
            }
            
            try db.create(table: "syncTaskValueDB") { table in
                
                table.autoIncrementedPrimaryKey("id")
                                
                table.column("objectType", .text)
                table.column("name", .text)
                    .notNull()
                table.column("value", .text)
                
                table.belongsTo("syncTask", inTable: "syncTaskDB", onDelete: .cascade)

            }
            
            try db.create(table: "idMappingDB") { table in
                table.column("localID", .integer)
                    .notNull()
                table.column("serverID", .integer)
                table.column("modelType", .text)
                    .notNull()
                
                table.primaryKey(["localID", "serverID", "modelType"])
            }
        }
        
        migrator.registerMigration("renameTransactionFieldAccounting") { db in
            try db.alter(table: "transactionDB") { table in
                table.rename(column: "accounting", to: "accountingInCharts")
            }
        }
        
        migrator.registerMigration("addDatetimeCreateInAccountGroups") { db in
            try db.alter(table: "accountGroupDB") { table in
                table.add(column: "datetimeCreate", .datetime)
                    .defaults(to: Date.now)
                    .notNull()
            }
        }
        
        migrator.registerMigration("addNotificationTokenInUser") { db in
            try db.alter(table: "userDB") { table in
                table.add(column: "notificationToken", .text)
            }
        }
        
        return migrator
    }
}
