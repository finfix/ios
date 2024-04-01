//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI

struct CurrencyRates: View {
    
    @State var vm = CurrencyRatesViewModel()
    var currencyFormatter = CurrencyFormatter()
        
    var body: some View {
        List(vm.currencies, id: \.code) { currency in
            HStack {
                Text(currency.code)
                Spacer()
                Text(currencyFormatter.string(number: currency.rate, currency: currency))
            }
        }
        .task {
            vm.load()
        }
    }
}

#Preview {
    CurrencyRates()
}
