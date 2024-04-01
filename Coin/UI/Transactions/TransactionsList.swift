//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "TransactionList")

struct TransactionsView: View {
    
    @State private var vm = TransactionsListViewModel()
    @Binding var selectedAccountGroup: AccountGroup
    
    @State private var searchText = ""
    @State var dateFrom: Date? = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: Date.now)!
    
    @State var dateTo: Date?
    @State var accountID: UInt32?
    @State var isFilterOpen = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date, style: .date).font(.headline)) {
                        ForEach(vm.groupedTransactionByDate[date]!) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .onDelete {
                            for i in $0.makeIterator() {
                                Task {
                                    await vm.deleteTransaction(vm.groupedTransactionByDate[date]![i])
                                }
                            }
                        }
                    }
                }
                if !vm.transactionsCancelled {
                    Text("Загрузка...")
                        .task {
                            vm.load(refresh: false)
                        }
                }
            }
            .navigationDestination(for: Transaction.self) { EditTransaction($0) }
            .listStyle(.grouped)
            .refreshable {
                vm.load(refresh: true)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Фильтры
                    Button { isFilterOpen.toggle() } label: { Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle") }
                }
            }
            .sheet(isPresented: $isFilterOpen) { TransactionFilterView(dateFrom: $dateFrom, dateTo: $dateTo) }
            .navigationTitle("Транзакции")

        }
    }
}

#Preview {
    TransactionsView(selectedAccountGroup: .constant(AccountGroup()))
}
