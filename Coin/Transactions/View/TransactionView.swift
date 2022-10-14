//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct TransactionView: View {
    
    /// Добавляем Network в качестве EnvironmentObject
    @StateObject var vm = TransactionViewModel()
    @State var showFilters = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(vm.transactionsFiltered, id: \.id) { transaction in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transaction.dateTransaction)
                            Text("\(transaction.accountFromID) -> \(transaction.accountToID)")
                                .font(.footnote)
                            
                            if transaction.amountTo == transaction.amountFrom {
                                Text(String(format: "%.2f", transaction.amountTo))
                                    .font(.footnote)
                            } else {
                                Text(String(format: "%.2f", transaction.amountFrom) + " -> " + String(format: "%.2f", transaction.amountTo))
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                        if let note = transaction.note {
                            Text(note)
                                .font(.footnote)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    vm.getTransaction()
                }
                .navigationBarTitle(Text("Транзакции"))
                .navigationBarItems(trailing: NavigationLink {
                    FilterView(withoutBalancing: self.$vm.withoutBalancing, transactionType: self.$vm.transactionType)
                } label: {
                    Text("Фильтры")
                }
                )
                    
            }
        }
    }
}

struct Transaction_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
