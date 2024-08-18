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
            try await service.sync()
        } catch {
            throw error
        }
    }
    
    func logout() async throws {
        try await service.logout()
    }
}
