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
            ZStack(alignment: .bottomTrailing) {
                VStack {
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
                    .navigationBarItems(trailing: NavigationLink {
                        TransactionFilterView(withoutBalancing: self.$vm.withoutBalancing, transactionType: self.$vm.transactionType)
                    } label: {
                        Text("Фильтры")
                    }
                    )
                    
                }
                NavigationLink(isActive: $showCreate) {
                    CreateTransactionView(isOpeningFrame: $showCreate)
                } label: {
                    ZStack {
                        Circle()
                            .frame(width: 50, height: 50)
                            .padding(20)
                            .foregroundColor(.gray)
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }
}

struct Transaction_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
        // ContentView()
    }
}
