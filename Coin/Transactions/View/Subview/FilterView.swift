//
//  FilterView.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

struct FilterView: View {
    
    @ObservedObject var vm = TransactionViewModel()
    @Binding var withoutBalancing: Bool
    @Binding var transactionType: Int
    
    var body: some View {
        VStack {
            Toggle("Без транзакций балансировки", isOn: $withoutBalancing)
            Picker(selection: $transactionType) {
                ForEach(0..<vm.types.count, id: \.self) {
                    Text(vm.types[$0])
                }
            } label: {
                Text("Тип транзакции")
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .navigationTitle("Фильтры")
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
    }
}
