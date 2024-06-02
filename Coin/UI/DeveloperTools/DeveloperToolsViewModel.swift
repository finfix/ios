//
//  DeveloperToolsViewModel.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import Foundation

@Observable
class DeveloperToolsViewModel {
    private let service = Service.shared
    
    func compareLocalAndServerData() async throws -> String? {
        return try await service.compareLocalAndServerData()
    }
}
