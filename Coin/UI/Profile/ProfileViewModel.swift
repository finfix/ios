//
//  ProfileViewModel.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation

@Observable
class ProfileViewModel {
    private let service = Service.shared
    
    func sync() async throws {
        do {
            try await service.sync()
        } catch {
            throw error
        }
    }
    
    func deleteAll() async throws {
        try await service.deleteAllData()
    }
}
