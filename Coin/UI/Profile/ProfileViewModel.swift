//
//  ProfileViewModel.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import Factory

@Observable
class ProfileViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    @ObservationIgnored
    @Injected(\.alertManager) var alert
    
    /// Доля выполненного sync() (0...1) — см. Service.sync(progress:).
    var syncProgress: Double = 0

    func sync() async throws {
        syncProgress = 0
        defer { syncProgress = 0 }
        do {
            guard try await service.getCountTasks() == 0 else {
                throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
            }
            try await service.sync(progress: { [weak self] fraction in
                Task { @MainActor in self?.syncProgress = fraction }
            })
        } catch {
            throw error
        }
    }
    
    func logout() async throws {
        guard try await service.getCountTasks() == 0 else {
            var isNeedLogout = false
            alert.warn(
                title: "Вы уверены?",
                message: "У вас есть фоновые задачи. Если вы выйдете, они не смогут быть синхронизированы с сервером") {
                isNeedLogout = true
            }
            
            if isNeedLogout {
                try await service.logout()
            }
            return
        }
    }
}
