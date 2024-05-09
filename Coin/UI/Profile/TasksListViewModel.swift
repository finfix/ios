//
//  TasksListViewModel.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation

@Observable
class TasksListViewModel {
    private let service = Service.shared

    var accountGroup = AccountGroup()
    var tasks: [SyncTask] = []

    func load() async throws {
        tasks = try await service.getSyncTasks()
    }
    
    func deleteAllTasks() async throws {
        try await service.deleteTasks()
    }
}
