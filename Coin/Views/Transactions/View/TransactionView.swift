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
    @State var showCreate = false
    @State var showUpdate = false
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $vm.searchText)
                List {
                    ForEach (vm.transactionsFiltered, id: \.id) { transaction in
                        NavigationLink(isActive: $showUpdate) {
                            UpdateTransactionView(isOpeningFrame: $showUpdate, t: transaction)
                        } label: {
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
                    }
                    .onDelete(perform: vm.deleteTransaction)
                }
                .onAppear {
                    vm.getTransaction()
                }
                .navigationBarTitle(Text("Транзакции"))
                .navigationBarItems(leading: NavigationLink {
                    TransactionFilterView(withoutBalancing: self.$vm.withoutBalancing, transactionType: self.$vm.transactionType)
                } label: {
                    Text("Фильтры")
                }, trailing: Button(action: {
                    vm.getTransaction()
                }, label: {
                    Image(systemName: "arrow.clockwise")
                }))
            }
        }
    }
}

struct Transaction_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
