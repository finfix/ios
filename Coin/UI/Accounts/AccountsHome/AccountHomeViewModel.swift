//
//  AccountHomeViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Factory

@Observable
class AccountHomeViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accounts: [Account] = []
    
    func load() async throws {
        accounts = try await service.getAccounts()
    }
}
