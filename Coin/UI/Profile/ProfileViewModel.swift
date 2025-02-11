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
            throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
        }
        try await service.logout()
    }
}
