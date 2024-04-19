//
//  TransactionsList.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI

enum TransactionsListRoute: Hashable {
    case editTransaction(Transaction)
}

struct TransactionsList: View {
    
    @Environment (AlertManager.self) private var alert
    @State private var vm: TransactionsListViewModel
    @Binding var selectedAccountGroup: AccountGroup
    
    var searchText: String
    var dateFrom: Date?
    var dateTo: Date?
    
    @Binding var path: NavigationPath
    
    init(
        path: Binding<NavigationPath>,
        selectedAccountGroup: Binding<AccountGroup>,
        account: Account? = nil,
        searchText: String = "",
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) {
        self._selectedAccountGroup = selectedAccountGroup
        self._path = path
        self.dateTo = dateTo
        self.dateFrom = dateFrom
        self.searchText = searchText
        vm = TransactionsListViewModel(account: account)
    }
    
    var groupedTransactionByDate: [Date: [Transaction]] {
        let filteredTransactions = vm.transactions.filter { $0.accountFrom.accountGroup == selectedAccountGroup }
        return Dictionary(grouping: filteredTransactions, by: { $0.dateTransaction })
    }
    
    var body: some View {
        List {
            ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(groupedTransactionByDate[date] ?? []) { transaction in
                        Button {
                            path.append(TransactionsListRoute.editTransaction(transaction))
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
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
                            try await vm.load(refresh: false, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText)
                        } catch {
                            alert(error)
                        }
                    }
            }
        }
        .task {
            if vm.transactions.count != 0 {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: dateFrom) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: dateTo) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText)
                } catch {
                    alert(error)
                }
            }
        }
        .navigationDestination(for: Transaction.self) { EditTransaction($0) }
        .listStyle(.grouped)
        .navigationTitle("Транзакции")
    }
}

#Preview {
    TransactionsList(path: .constant(NavigationPath()), selectedAccountGroup: .constant(AccountGroup()))
        .environment(AlertManager(handle: {_ in }))
}
