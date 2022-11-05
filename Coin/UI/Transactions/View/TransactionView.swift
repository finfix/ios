//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import RealmSwift

struct TransactionView: View {
    
    @Environment(\.realm) var realm
    
    @StateObject var vm = TransactionViewModel()
    
    @EnvironmentObject var appSettings: AppSettings
    
    @ObservedResults (
        Transaction.self,
        sortDescriptor: SortDescriptor(keyPath: "dateTransaction", ascending: false)
    ) var transactions
    
    @State var showFilters = false
    @State var showCreate = false
    @State var showUpdate = false
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $vm.searchText)
                List {
                    ForEach (transactions, id: \.id) { transaction in
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
                    .onDelete {
                        for i in $0 {
                            vm.deleteTransaction(id: transactions[i].id, appSettings)
                        }
                    }
                }
                .navigationBarItems(leading: NavigationLink {
                    TransactionFilterView(withoutBalancing: self.$vm.withoutBalancing, transactionType: self.$vm.transactionType)
                } label: {
                    Text("Фильтры")
                }, trailing: Button(action: {

                    TransactionAPI().GetTransactions() { response, error in
                                    if let err = error {
                                        appSettings.showErrorAlert(error: err)
                                    } else if let response = response {
                                        try? self.realm.write {
                                            self.realm.delete(self.realm.objects(Transaction.self))
                                            self.realm.add(response)
                                        }
                                    }
                                }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                }))
                
            }
            .onAppear { vm.getTransaction(appSettings) }
            .navigationBarTitle("Транзакции")
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct Transaction_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
