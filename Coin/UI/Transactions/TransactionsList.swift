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
    
    @Environment (AlertManager.self) private var alert
    
    init(
        selectedAccountGroup: Binding<AccountGroup>,
        account: Account? = nil
    ) {
        self._selectedAccountGroup = selectedAccountGroup
        vm = TransactionsListViewModel(account: account)
    }
    
    @State private var vm: TransactionsListViewModel
    @Binding var selectedAccountGroup: AccountGroup
    
    var groupedTransactionByDate: [Date: [Transaction]] {
        let filteredTransactions = vm.transactions.filter { $0.accountFrom.accountGroup == selectedAccountGroup }
        return Dictionary(grouping: filteredTransactions, by: { $0.dateTransaction })
    }
    
    @State private var searchText = ""
    @State var dateFrom: Date? = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: Date.now)!
    
    @State var dateTo: Date?
    @State var isFilterOpen = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date, style: .date).font(.headline)) {
                        ForEach(groupedTransactionByDate[date] ?? []) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .onDelete {
                            for i in $0.makeIterator() {
                                Task {
                                    do {
                                        try await vm.deleteTransaction(groupedTransactionByDate[date]![i])
                                    } catch {
                                        alert(error)
                                    }
                                }
                            }
                        }
                    }
                }
                if !vm.transactionsCancelled {
                    Text("Загрузка...")
                        .task {
                            do {
                                try vm.load(refresh: false)
                            } catch {
                                alert(error)
                            }
                        }
                }
            }
            .task {
                if vm.transactions.count != 0 {
                    do {
                        try vm.load(refresh: true)
                    } catch {
                        alert(error)
                    }
                }
            }
            .navigationDestination(for: Transaction.self) { EditTransaction($0) }
            .listStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Фильтры
                    Button { isFilterOpen.toggle() } label: { Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle") }
                }
                if vm.accountIDs.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        AccountGroupSelector(selectedAccountGroup: $selectedAccountGroup)
                    }
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
