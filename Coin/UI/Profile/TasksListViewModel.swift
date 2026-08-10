//
//  TasksListViewModel.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation
import Factory

@Observable
class TasksListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    var accountGroup = AccountGroup()
    var tasks: [SyncTask] = []
    var showCompleted = false

    func load() async throws {
        tasks = try await service.taskManager.getSyncTasks(includeCompleted: showCompleted)
    }

    func deleteAllTasks() async throws {
        try await service.taskManager.completeTasks()
    }
}
