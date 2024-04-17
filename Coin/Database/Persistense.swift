//
//  LocalDatabase+Persistent.swift
//  Coin
//
//  Created by Илья on 14.05.2024.
//

import Foundation
import GRDB

extension AppDatabase {

    static let shared = makeShared()

    static func makeShared() -> AppDatabase {
        do {

            let fileManager = FileManager()

            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let directoryURL = appSupportURL.appendingPathComponent("database", isDirectory: true)
            
            if CommandLine.arguments.contains("-reset") {
                try? fileManager.removeItem(at: directoryURL)
            }

            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
        
            NSLog("Database stored at \(databaseURL.path)")

            let dbPool = try DatabasePool(
                path: databaseURL.path,
                // Use default AppDatabase configuration
                configuration: AppDatabase.makeConfiguration())
            
            let appDatabase = try AppDatabase(dbPool)

            return appDatabase

        } catch {
            fatalError("ERROR: \(error)")
        }
    }
}


