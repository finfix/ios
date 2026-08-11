//
//  DeveloperToolsViewModel.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import Foundation
import Factory

@Observable
class DeveloperToolsViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    func compareLocalAndServerData() async throws -> String? {
        return try await service.compareLocalAndServerData()
    }
    
    func reconnectGRPC(host: String, port: Int) throws {
        try service.reconnectGRPC(host: host, port: port)
    }

    func forceRefreshTokens() async throws {
        try await service.forceRefreshTokens()
    }

    // MARK: - Инкрементальная синхронизация

    var taskManager: TaskManager { service.taskManager }

    func triggerIncrementalSync() async throws {
        try await service.incrementalSync()
    }

    /// Сбрасывает локальный чекпоинт синхронизации на 0 — следующий incrementalSync() заново
    /// перекачает и переприменит всю доступную историю (полезно для отладки applySyncChanges).
    func resetSyncCheckpoint() {
        SyncStateStorage.shared.lastSyncedAuditLogID = 0
    }
}
