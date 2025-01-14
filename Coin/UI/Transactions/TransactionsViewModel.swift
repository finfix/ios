//
//  TransactionsViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Factory

@Observable
class TransactionsViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var user: User = User()
        
    @MainActor
    func load() async throws {
        self.user = try await service.getUsers()[0]
    }
}
