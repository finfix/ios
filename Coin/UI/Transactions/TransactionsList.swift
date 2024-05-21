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
    
    var filters: TransactionFilters
    var chartType: ChartType
    
    @Binding var path: NavigationPath
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    init(
        path: Binding<NavigationPath>,
        selectedAccountGroup: Binding<AccountGroup>,
        filters: TransactionFilters,
        chartType: ChartType
    ) {
        self._selectedAccountGroup = selectedAccountGroup
        self._path = path
        self.filters = filters
        self.chartType = chartType
        self.vm = TransactionsListViewModel()
    }
    
    var groupedTransactionByDate: [Date: [Transaction]] {
        let filteredTransactions = vm.transactions.filter { $0.accountFrom.accountGroup == selectedAccountGroup }
        return Dictionary(grouping: filteredTransactions, by: { $0.dateTransaction })
    }
    
    var body: some View {
        List {
            Section(footer:
                ChartView(
                    chartType: chartType,
                    selectedAccountGroup: selectedAccountGroup, 
                    filters: filters,
                    path: $path
                )
                .frame(width: width, height: height*0.6)
            ){}
            ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(groupedTransactionByDate[date] ?? []) { transaction in
                        NavigationLink(value: TransactionsListRoute.editTransaction(transaction)) {
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
                            try await vm.load(refresh: false, filters: filters)
                        } catch {
                            alert(error)
                        }
                    }
            }
        }
        .task {
            if vm.transactions.count != 0 {
                do {
                    try await vm.load(refresh: true, filters: filters)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: filters) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, filters: filters)
                } catch {
                    alert(error)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Транзакции")
    }
}

#Preview {
    TransactionsList(
        path: .constant(NavigationPath()),
        selectedAccountGroup: .constant(AccountGroup(
            id: 4,
            currency: Currency(
                symbol: "₽"
            )
        )), 
        filters: TransactionFilters(),
        chartType: .earningsAndExpenses
    )
    .environment(AlertManager(handle: {_ in }))
}
