//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI
import SwiftData

struct CurrencyRates: View {
    
    @Query(sort: [
        SortDescriptor(\Currency.isoCode)
    ]) var currencies: [Currency]
    @Environment(\.modelContext) var modelContext
    
    var currencyFormatter = CurrencyFormatter()
    
    var body: some View {
        List(currencies) { currency in
            HStack {
                Text(currency.isoCode)
                Spacer()
                Text(currencyFormatter.string(number: currency.rate, currency: currency))
            }
        }
    }
}

#Preview {
    CurrencyRates()
}
