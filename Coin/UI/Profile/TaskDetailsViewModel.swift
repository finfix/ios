//
//  TaskDetailsViewModel.swift
//  Coin
//
//  Created by Илья on 10.05.2024.
//

import Foundation
import Factory

@Observable
class TasksDetailsViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    var task: SyncTask
    
    init(task: SyncTask) {
        self.task = task
    }

    func load() async throws {
        let tasks = try await service.taskManager.getSyncTasks(ids: [task.id])
        guard !tasks.isEmpty else {
            throw ErrorModel(humanText: "Задача уже выполнена или удалена")
        }
        task = tasks[0]
    }
    
    func delete() async throws {
        try await service.taskManager.deleteTasks(ids: [task.id])
    }
    
    func deleteAllTasks() async throws {
        try await service.taskManager.deleteTasks()
    }
}
