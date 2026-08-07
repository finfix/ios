//
//  CurrencyPicker.swift
//  Coin
//

import SwiftUI

struct CurrencyPicker: View {

    @Binding var selectedCurrency: Currency
    let currencies: [Currency]
    @State private var searchText: String = ""
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFocused: Bool

    var filtered: [Currency] {
        searchText.isEmpty ? currencies : currencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filtered, id: \.code) { (currency: Currency) in
                Button {
                    selectedCurrency = currency
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(currency.code).bold()
                            if !currency.name.isEmpty {
                                Text(currency.name).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if currency == selectedCurrency {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск валюты")
        .searchFocused($isSearchFocused)
        .navigationTitle("Выбор валюты")
        .onAppear {
            isSearchFocused = true
        }
    }
}
