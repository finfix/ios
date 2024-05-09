//
//  TaskDetailsViewModel.swift
//  Coin
//
//  Created by Илья on 10.05.2024.
//

import Foundation

@Observable
class TasksDetailsViewModel {
    private let service = Service.shared

    var task: SyncTask
    
    init(task: SyncTask) {
        self.task = task
    }

    func load() async throws {
        let tasks = try await service.getSyncTasks(ids: [task.id])
        guard !tasks.isEmpty else {
            throw ErrorModel(humanTextError: "Задача уже выполнена или удалена")
        }
        task = tasks[0]
    }
    
    func delete() async throws {
        try await service.deleteTasks(ids: [task.id])
    }
    
    func deleteAllTasks() async throws {
        try await service.deleteTasks()
    }
}
