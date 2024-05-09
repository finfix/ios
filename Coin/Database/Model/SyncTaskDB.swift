//
//  SyncTaskDB.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation
import GRDB

struct SyncTaskDB {
    
    var id: UInt32?
    var localID: UInt32
    var actionName: ActionName
    var error: String?
    var tryCount: UInt32
    var enabled: Bool
    
    // Инициализатор из бизнес модели
    init(_ model: SyncTask) {
        self.id = model.id
        if self.id == 0 {
            self.id = nil
        }
        self.error = model.error
        self.localID = model.localID
        self.actionName = model.actionName
        self.tryCount = model.tryCount
        self.enabled = model.enabled
    }
}

// MARK: - Persistence
extension SyncTaskDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let localID = Column(CodingKeys.localID)
        static let actionName = Column(CodingKeys.actionName)
        static let tryCount = Column(CodingKeys.tryCount)
        static let error = Column(CodingKeys.error)
        static let enabled = Column(CodingKeys.enabled)
    }
}

struct SyncTaskValueDB {
    
    var id: UInt32?
    var syncTaskID: UInt32? = nil
    var objectType: ModelType? = nil
    var name: String
    var value: String?
    
    // Инициализатор из бизнес модели
    init(_ model: SyncTaskValue) {
        self.id = model.id
        if self.id == 0 {
            self.id = nil
        }
        self.syncTaskID = model.syncTaskID
        self.objectType = model.objectType
        self.name = model.name
        self.value = model.value
    }
}

// MARK: - Persistence
extension SyncTaskValueDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let syncTaskID = Column(CodingKeys.syncTaskID)
        static let objectType = Column(CodingKeys.objectType)
        static let name = Column(CodingKeys.name)
        static let value = Column(CodingKeys.value)
    }
}
