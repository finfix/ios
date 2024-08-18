//
//  CurrencyRatesViewModel.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import Factory

@Observable
class CurrencyRatesViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var currencies: [Currency] = []
    var user = User()
    
    func load() async throws {
        currencies = try await service.getCurrencies()
        let users = try await service.getUsers()
        if !users.isEmpty {
            user = users.first!
        }
    }
}
