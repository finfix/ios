//
//  CurrencyRatesViewModel.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation

@Observable
class CurrencyRatesViewModel {
    private let service = Service.shared
    
    var currencies: [Currency] = []
    
    func load() throws {
        currencies = try service.getCurrencies()
    }
}
