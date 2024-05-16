//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI

struct CurrencyConverter: View {
    
    @State var vm = CurrencyRatesViewModel()
    @Environment (AlertManager.self) private var alert

    var currencyFormatter = CurrencyFormatter(maximumFractionDigits: 2, withUnits: false)
    
    @State var currency1 = Currency()
    @State var currency2 = Currency()
    @State var currencyFind: String = ""
    @State var number: Double = 0
    var number2: Double {
        number * (currency2.rate / currency1.rate).doubleValue
    }
        
    var body: some View {
        Form {
            Section {
                Picker("Валюта 1", selection: $currency1) {
                    ForEach(vm.currencies) { currency in
                        Text("\(currency.name) (\(currency.code))")
                            .tag(currency)
                    }
                }
                Picker("Валюта 2", selection: $currency2) {
                    ForEach(vm.currencies) { currency in
                        Text("\(currency.name) (\(currency.code))")
                            .tag(currency)
                    }
                }
                Button {
                    (currency1, currency2) = (currency2, currency1)
                } label: {
                    Text("Поменять местами")
                }
            }
            Section {
                TextField("", value: $number, format: .number)
                    .keyboardType(.numberPad)
                Text(CurrencyFormatter(
                    currency: currency2,
                    maximumFractionDigits: 2,
                    withUnits: false
                ).string(number: Decimal(number2)))
            }
        }
        .task {
            do {
                try await vm.load()
                currency1 = vm.currencies.first(where: { $0.code == "USD" }) ?? Currency()
                currency2 = vm.user.defaultCurrency
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    CurrencyConverter()
        .environment(AlertManager(handle: {_ in }))
}
