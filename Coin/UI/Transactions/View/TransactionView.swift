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
            // Строка поиска
            VStack {
                SearchBar(searchText: $vm.searchText)
                
                // Список транзакций
                List {
                    ForEach(vm.transactionByDate.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date, style: .date).font(.headline)) {
                            ForEach (vm.transactionsFiltered.filter{ $0.dateTransaction == date }, id: \.id) { transaction in
                                switch transaction.typeSignatura {
                                case "balancing":
                                    
                                    HStack {
                                        Text(vm.accountsMap[transaction.accountToID]?.name ?? "")
                                        Text(String(format: "%.2f", transaction.amountTo))
                                    }.padding()
                                default:
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            // Счета
                                            Text(vm.accountsMap[transaction.accountFromID]?.name ?? "Нет счета")
                                                .font(.footnote)
                                            Text(vm.accountsMap[transaction.accountToID]?.name ?? "Нет счета")
                                        }
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            // Сумма
                                            Text(String(format: "%.2f", transaction.amountTo))
                                            
                                            // Заметка
                                            if let note = transaction.note {
                                                Text(note)
                                                    .font(.footnote)
                                            }
                                        }
                                    }
                                    .padding()
                                    .navigationDestination(isPresented: $showUpdate) {
                                        UpdateTransactionView(isOpeningFrame: $showUpdate, t: transaction)
                                    }
                                }
                            }
                            .onDelete { vm.deleteTransaction(at: $0, appSettings) }
                        }
                    }
                }
            }
            
            // Верхняя панель
            .navigationBarItems(trailing: Button(action: {
                vm.getTransaction(appSettings)
            }, label: {
                Image(systemName: "arrow.clockwise")
            }))
            .onAppear { vm.getTransaction(appSettings) }
            .onAppear { vm.getAccount() }
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

struct transactionRowView: View {
    
    @State var accounts: [Int: Account]
    @State var transaction: Transaction
    @Binding var showUpdate: Bool
    
    var body: some View {
        // Переход на редактирование
        NavigationLink(isActive: $showUpdate) {
            UpdateTransactionView(isOpeningFrame: $showUpdate, t: transaction)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    // Счета
                    Text(accounts[transaction.accountFromID]?.name ?? "Нет счета")
                        .font(.footnote)
                    Text(accounts[transaction.accountToID]?.name ?? "Нет счета")
                }
                Spacer()
                
                VStack(alignment: .trailing) {
                    // Сумма
                    Text(String(format: "%.2f", transaction.amountTo))
                    
                    // Заметка
                    if let note = transaction.note {
                        Text(note)
                            .font(.footnote)
                    }
                }
            }
            .padding()
        }
    }
}
