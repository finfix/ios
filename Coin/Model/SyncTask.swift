//
//  SyncTask.swift
//  Coin
//
//  Created by Илья on 07.05.2024.
//

import Foundation

struct SyncTask: Identifiable, Hashable {
    
    var id: UInt32
    var localID: UInt32
    var actionName: ActionName
    var tryCount: UInt32
    var error: String?
    var fields: [SyncTaskValue]
    var enabled: Bool
    
    init(
        id: UInt32 = 0,
        localID: UInt32 = 0,
        actionName: ActionName = .createTag,
        tryCount: UInt32 = 0,
        error: String? = nil,
        fields: [SyncTaskValue] = [],
        enabled: Bool = true
    ) {
        self.id = id
        self.localID = localID
        self.actionName = actionName
        self.tryCount = tryCount
        self.error = error
        self.fields = fields
        self.enabled = enabled
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: SyncTaskDB, syncTaskValues: [SyncTaskValue]) {
        self.id = dbModel.id!
        self.localID = dbModel.localID
        self.actionName = dbModel.actionName
        self.tryCount = dbModel.tryCount
        self.error = dbModel.error
        self.enabled = dbModel.enabled
        self.fields = syncTaskValues
    }
    
    static func convertFromDBModel(_ tasksDB: [SyncTaskDB], syncTaskValuesMap: [UInt32: [SyncTaskValue]]) -> [SyncTask] {
        var tasks: [SyncTask] = []
        for taskDB in tasksDB {
            tasks.append(SyncTask(taskDB, syncTaskValues: syncTaskValuesMap[taskDB.id!]!))
        }
        return tasks
    }
}

struct SyncTaskValue: Identifiable, Hashable {
    
    var id: UInt32
    var syncTaskID: UInt32? = nil
    var objectType: ModelType? = nil
    var name: String
    var value: String?
    
    init(
         id: UInt32 = 0,
         syncTaskID: UInt32? = nil,
         objectType: ModelType? = nil,
         name: String,
         value: String?
    ) {
        self.id = id
        self.syncTaskID = syncTaskID
        self.objectType = objectType
        self.name = name
        self.value = value
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: SyncTaskValueDB) {
        self.id = dbModel.id!
        self.syncTaskID = dbModel.syncTaskID
        self.objectType = dbModel.objectType
        self.name = dbModel.name
        self.value = dbModel.value
    }
    
    static func groupByTaskID(_ values: [SyncTaskValue]) -> [UInt32: [SyncTaskValue]] {
        return Dictionary(grouping: values, by: { $0.syncTaskID! })
    }
    
    static func convertFromDBModel(_ tasksValuesDB: [SyncTaskValueDB]) -> [SyncTaskValue] {
        var taskValues: [SyncTaskValue] = []
        for taskValueDB in tasksValuesDB {
            taskValues.append(SyncTaskValue(taskValueDB))
        }
        return taskValues
    }
}
