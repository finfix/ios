//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI
import Combine

struct CurrencyRates: View {
    
    var currencyFormatter = CurrencyFormatter()
    
    @StateObject private var viewModel = CurrencyRatesViewModel()
    
    var body: some View {
        List(viewModel.currencies, id: \.code) { currency in
            HStack {
                Text(currency.code)
                Spacer()
                Text(currencyFormatter.string(number: currency.rate, currency: currency))
            }
        }
    }
}

#Preview {
    CurrencyRates()
}

class CurrencyRatesViewModel: ObservableObject {
    
    @Published var currencies: [Currency] = []
    
    private let db = LocalDatabase.shared
    
    init() {
        db
            .observeCurrencies()
            .catch { err in
                return Just([])
            }
            .assign(to: &$currencies)
    }
    
    func createCurrency() async {
        do {
            try await db.importCurrencies([Currency(code: "cst", name: "custom", rate: 1, symbol: "£")])
        } catch {
            print(error)
        }
    }
}
