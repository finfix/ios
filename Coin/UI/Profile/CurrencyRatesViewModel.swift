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
    
    func load() {
        do {
            currencies = try service.getCurrencies()
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
