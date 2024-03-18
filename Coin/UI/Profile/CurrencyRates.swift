//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI
import GRDBQuery

struct CurrencyRates: View {
    
    @Environment(\.appDatabase) private var appDatabase
    
    @Query(CurrencyRequest(ordering: .byCode)) private var currencies: [Currency]
    
    var currencyFormatter = CurrencyFormatter()
        
    var body: some View {
        List(currencies, id: \.code) { currency in
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
