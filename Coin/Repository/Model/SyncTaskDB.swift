//
//  SyncTaskDB.swift
//  Coin
//

import Foundation
import GRDB

struct SyncTaskDB {

    var id: UUID?
    var actionName: ActionName
    var error: String?
    var tryCount: UInt32
    var completed: Bool
    var fieldsJson: Data
    var datetimeCreate: Date
    var entityID: UUID
    /// JSON-массив UUID — GRDB не хранит массивы нативно, а зависимостей у одной таски
    /// обычно единицы, так что доп. таблица здесь была бы избыточной.
    var dependsOnTaskIDsJSON: Data

    // Инициализатор из бизнес модели
    init(_ model: SyncTask) {
        self.id = model.id
        if self.id == nil {
            self.id = nil
        }
        self.error = model.error
        self.actionName = model.actionName
        self.tryCount = model.tryCount
        self.completed = model.completed
        self.fieldsJson = model.fieldsJSON
        self.datetimeCreate = model.datetimeCreate
        self.entityID = model.entityID
        self.dependsOnTaskIDsJSON = (try? JSONEncoder().encode(model.dependsOnTaskIDs)) ?? Data("[]".utf8)
    }
}

// MARK: - Persistence
extension SyncTaskDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let actionName = Column(CodingKeys.actionName)
        static let tryCount = Column(CodingKeys.tryCount)
        static let error = Column(CodingKeys.error)
        static let completed = Column(CodingKeys.completed)
        static let fieldsJson = Column(CodingKeys.fieldsJson)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
        static let entityID = Column(CodingKeys.entityID)
        static let dependsOnTaskIDsJSON = Column(CodingKeys.dependsOnTaskIDsJSON)
    }
}
