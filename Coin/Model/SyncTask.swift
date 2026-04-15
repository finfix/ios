//
//  SyncTask.swift
//  Coin
//
//  Created by Илья on 07.05.2024.
//

import Foundation

struct SyncTask: Identifiable, Hashable {

    var id: UUID
    var actionName: ActionName
    var tryCount: UInt32
    var error: String?
    var fieldsJSON: Data
    var enabled: Bool
    var datetimeCreate: Date

    init(
        id: UUID = UUID(),
        actionName: ActionName = .createTag,
        tryCount: UInt32 = 0,
        error: String? = nil,
        fieldsJSON: Data = Data(),
        enabled: Bool = true,
        datetimeCreate: Date = Date()
    ) {
        self.id = id
        self.actionName = actionName
        self.tryCount = tryCount
        self.error = error
        self.fieldsJSON = fieldsJSON
        self.enabled = enabled
        self.datetimeCreate = datetimeCreate
    }

    // Инициализатор из модели базы данных
    init(_ dbModel: SyncTaskDB) throws {
        self.id = dbModel.id!
        self.actionName = dbModel.actionName
        self.tryCount = dbModel.tryCount
        self.error = dbModel.error
        self.enabled = dbModel.enabled
        self.fieldsJSON = dbModel.fieldsJson
        self.datetimeCreate = dbModel.datetimeCreate
    }
    
    static func convertFromDBModel(_ tasksDB: [SyncTaskDB]) throws -> [SyncTask] {
        var tasks: [SyncTask] = []
        for taskDB in tasksDB {
            tasks.append(try SyncTask(taskDB))
        }
        return tasks
    }
}
