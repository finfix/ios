//
//  TransactionFilterViewModel.swift
//  Coin
//
//  Created by Илья on 01.05.2024.
//

import Foundation
import Factory

@Observable
class TransactionFilterViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var currencies: [Currency] = []
    
    func load() async throws {
        currencies = try await service.getCurrencies()
    }
}
