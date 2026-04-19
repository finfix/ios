//
//  SyncTaskDB.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation
import GRDB

struct SyncTaskDB {

    var id: UUID?
    var actionName: ActionName
    var error: String?
    var tryCount: UInt32
    var enabled: Bool
    var fieldsJson: Data
    var datetimeCreate: Date

    // Инициализатор из бизнес модели
    init(_ model: SyncTask) {
        self.id = model.id
        if self.id == nil {
            self.id = nil
        }
        self.error = model.error
        self.actionName = model.actionName
        self.tryCount = model.tryCount
        self.enabled = model.enabled
        self.fieldsJson = model.fieldsJSON
        self.datetimeCreate = model.datetimeCreate
    }
}

// MARK: - Persistence
extension SyncTaskDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let actionName = Column(CodingKeys.actionName)
        static let tryCount = Column(CodingKeys.tryCount)
        static let error = Column(CodingKeys.error)
        static let enabled = Column(CodingKeys.enabled)
        static let fieldsJson = Column(CodingKeys.fieldsJson)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
    }
}
