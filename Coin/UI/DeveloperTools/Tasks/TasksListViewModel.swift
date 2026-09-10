//
//  TasksListViewModel.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation
import Factory
import GRDB

@Observable
class TasksListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    var accountGroup = AccountGroup()
    var tasks: [SyncTask] = []
    var showCompleted = false

    /// Живая подписка вместо ручного load()/.refreshable — экран сам обновляется на любое
    /// изменение syncTaskDB (executeDBTasks, createTask, incrementalSync), см. Repository.observeSyncTasks.
    func observeTasks() -> AsyncValueObservation<[SyncTask]> {
        service.taskManager.observeSyncTasks(includeCompleted: showCompleted)
    }

    func deleteAllTasks() async throws {
        try await service.taskManager.completeTasks()
    }
}
