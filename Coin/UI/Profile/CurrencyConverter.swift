//
//  CurrencyRates.swift
//  Coin
//
//  Created by Илья on 01.11.2023.
//

import SwiftUI

struct CurrencyConverter: View {
    
    @State var vm = CurrencyRatesViewModel()
    @Environment(AlertManager.self) private var alert
    
    @State private var isNumber1Focused = false
    @State private var isNumber2Focused = false

    @State var currency1 = Currency()
    @State var currency2 = Currency()
    @State var currencyFind: String = ""
    @State var number1: Double = 0
    @State var number2: Double = 0
        
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
            }
            Section {
                CalculatorField(
                    title: "Сумма первой валюты",
                    value: $number1,
                    isFocused: $isNumber1Focused
                )
                    .overlay(alignment: .trailing) {
                        Text(currency1.symbol)
                    }
                    .onChange(of: number1) { _, newValue in
                        number2 = newValue * (currency2.rate / currency1.rate).doubleValue
                    }
                CalculatorField(
                    title: "Сумма второй валюты",
                    value: $number2,
                    isFocused: $isNumber2Focused
                )
                    .overlay(alignment: .trailing) {
                        Text(currency2.symbol)
                    }
                    .onChange(of: number2) { _, newValue in
                        number1 = newValue * (currency1.rate / currency2.rate).doubleValue
                    }
            }

        }
        .task {
            do {
                try await vm.load()
                currency1 = vm.currencies.first(where: { $0.code == "USD" }) ?? Currency()
                currency2 = vm.user.defaultCurrency
            } catch {
                alert.error(error)
            }
        }
    }
}

#Preview {
    CurrencyConverter()
        .environment(AlertManager(handle: {_ in }))
}
