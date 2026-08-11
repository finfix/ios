//
//  TaskGraphViewModel.swift
//  Coin
//

import Foundation
import Factory

@Observable
class TaskGraphViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    var tasks: [SyncTask] = []
    var showCompleted = false

    struct Node: Identifiable {
        let task: SyncTask
        var id: UUID { task.id }
        var layer: Int
    }

    func load() async throws {
        tasks = try await service.taskManager.getSyncTasks(includeCompleted: showCompleted)
    }

    // Раскладывает таски по "волнам" (слоям) на основе dependsOnTaskIDs — таска попадает в
    // слой на единицу выше самой глубокой из своих ещё видимых зависимостей. Зависимости,
    // отсутствующие в видимом наборе (например, уже выполненная и скрытая таска), считаются
    // разрешёнными сразу.
    var nodes: [Node] {
        let idSet = Set(tasks.map(\.id))
        var layer: [UUID: Int] = [:]
        var resolved = Set<UUID>()
        var remaining = tasks

        var iterations = 0
        while !remaining.isEmpty && iterations <= tasks.count {
            iterations += 1
            var progressed = false
            for task in remaining where layer[task.id] == nil {
                let deps = task.dependsOnTaskIDs.filter { idSet.contains($0) }
                if deps.allSatisfy({ resolved.contains($0) }) {
                    let depLayer = deps.compactMap { layer[$0] }.max() ?? -1
                    layer[task.id] = depLayer + 1
                    resolved.insert(task.id)
                    progressed = true
                }
            }
            remaining.removeAll { layer[$0.id] != nil }
            if !progressed { break }
        }

        // Всё, что не удалось разрешить (цикл — в норме не должно случаться), кладём в
        // отдельный последний слой, чтобы не потерять из вида.
        if !remaining.isEmpty {
            let maxResolvedLayer = layer.values.max() ?? -1
            for task in remaining {
                layer[task.id] = maxResolvedLayer + 1
            }
        }

        return tasks.map { Node(task: $0, layer: layer[$0.id] ?? 0) }
    }

    var edges: [(from: UUID, to: UUID)] {
        let idSet = Set(tasks.map(\.id))
        return tasks.flatMap { task in
            task.dependsOnTaskIDs
                .filter { idSet.contains($0) }
                .map { (from: $0, to: task.id) }
        }
    }
}
