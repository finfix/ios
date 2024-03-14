//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI

struct CurrencyRates: View {
    
    var currencies: [Currency] = []
    
    var currencyFormatter = CurrencyFormatter()
    
    var body: some View {
        List(currencies) { currency in
            HStack {
                Text(currency.id)
                Spacer()
                Text(currencyFormatter.string(number: currency.rate, currency: currency))
            }
        }
    }
}

#Preview {
    CurrencyRates()
}
