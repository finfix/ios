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
    
    func sync() async throws {
        do {
            guard try await service.getCountTasks() == 0 else {
                throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
            }
            try await service.sync()
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
