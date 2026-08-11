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
    var completed: Bool
    var datetimeCreate: Date
    /// id объекта, который создаёт/меняет эта таска — используется планировщиком, чтобы
    /// несколько тасок над одним и тем же объектом не выполнялись параллельно/не в том
    /// порядке (см. TaskManager.createTask).
    var entityID: UUID
    /// Таски (по id), которые должны быть обработаны раньше этой — либо потому что относятся
    /// к тому же entityID, либо потому что эта таска явно ссылается на другую сущность,
    /// которая ещё не подтверждена сервером (например, транзакция на ещё не созданный счёт).
    var dependsOnTaskIDs: [UUID]

    init(
        id: UUID = UUID(),
        actionName: ActionName = .createTag,
        tryCount: UInt32 = 0,
        error: String? = nil,
        fieldsJSON: Data = Data(),
        completed: Bool = false,
        datetimeCreate: Date = Date(),
        entityID: UUID = UUID(),
        dependsOnTaskIDs: [UUID] = []
    ) {
        self.id = id
        self.actionName = actionName
        self.tryCount = tryCount
        self.error = error
        self.fieldsJSON = fieldsJSON
        self.completed = completed
        self.datetimeCreate = datetimeCreate
        self.entityID = entityID
        self.dependsOnTaskIDs = dependsOnTaskIDs
    }

    // Инициализатор из модели базы данных
    init(_ dbModel: SyncTaskDB) throws {
        self.id = dbModel.id!
        self.actionName = dbModel.actionName
        self.tryCount = dbModel.tryCount
        self.error = dbModel.error
        self.completed = dbModel.completed
        self.fieldsJSON = dbModel.fieldsJson
        self.datetimeCreate = dbModel.datetimeCreate
        self.entityID = dbModel.entityID
        self.dependsOnTaskIDs = (try? JSONDecoder().decode([UUID].self, from: dbModel.dependsOnTaskIDsJSON)) ?? []
    }
    
    static func convertFromDBModel(_ tasksDB: [SyncTaskDB]) throws -> [SyncTask] {
        var tasks: [SyncTask] = []
        for taskDB in tasksDB {
            tasks.append(try SyncTask(taskDB))
        }
        return tasks
    }
}
