//
//  SQLite.swift
//  Coin
//
//  Created by Илья on 16.03.2024.
//

import Foundation
import GRDB
import OSLog

private let logger = Logger(subsystem: "Coin", category: "Repository")

struct SQLite {
    
    init() throws {
        
        // Получаем менеджера файлов
        let fileManager = FileManager()

        // Формируем URL до директивы с базой данных
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL.appendingPathComponent("database", isDirectory: true)
        
        // Если передан аргумент -reset в командной строке
        if CommandLine.arguments.contains("-reset") {
            
            // Удаляем файл базы директивы с базой данных
            try? fileManager.removeItem(at: directoryURL)
        }

        // Создаем директиву
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        // Формируем путь до файла базы данных
        let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
    
        logger.info("Database stored at \(databaseURL.path)")

        // Инициализируем базу данных
        db = try DatabasePool(
            path: databaseURL.path,
            configuration: SQLite.makeConfiguration())
        
        // Запускаем миграции
        try migrator.migrate(db)
    }

    private let db: any DatabaseWriter
    
    public func write<T>(_ updates: @Sendable @escaping (Database) throws -> T) async throws -> T {
        return try await db.write(updates)
    }
    
    public func read<T>(_ value: @Sendable @escaping (Database) throws -> T) async throws -> T {
        try await db.read(value)
    }
    
    
    private static let sqlLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SQL")
    
    private static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base
                
        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace {
                    os_log("%{public}@", log: sqlLogger, type: .debug, String(describing: $0))
                }
            }
        }
        
#if DEV
        config.publicStatementArguments = true
#endif
        
        return config
    }
}
