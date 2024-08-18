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
}
