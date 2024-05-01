//
//  TransactionFilterViewModel.swift
//  Coin
//
//  Created by Илья on 01.05.2024.
//

import Foundation

@Observable
class TransactionFilterViewModel {
    private var service = Service.shared
    
    var currencies: [Currency] = []
    
    func load() async throws {
        currencies = try await service.getCurrencies()
    }
}
