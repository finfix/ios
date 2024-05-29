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
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    
    var filters: TransactionFilters
    var chartType: ChartType
    
    @Environment(PathSharedState.self) var path
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    init(
        filters: TransactionFilters,
        chartType: ChartType
    ) {
        self.filters = filters
        self.chartType = chartType
        self.vm = TransactionsListViewModel()
    }
    
    var body: some View {
        List {
            Section(footer:
                ChartView(
                    chartType: chartType,
                    selectedAccountGroup: selectedAccountGroup.selectedAccountGroup,
                    filters: filters
                )
                .frame(width: width, height: height*0.6)
            ){}
            ForEach(vm.groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(vm.groupedTransactionByDate[date] ?? []) { transaction in
                        NavigationLink(value: TransactionsListRoute.editTransaction(transaction)) {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete {
                        for i in $0.makeIterator() {
                            Task {
                                do {
                                    try await vm.deleteTransaction(vm.groupedTransactionByDate[date]![i], selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
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
                            try await vm.load(refresh: false, filters: filters, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                        } catch {
                            alert(error)
                        }
                    }
            }
        }
        .task {
            if vm.groupedTransactionByDate.count != 0 {
                do {
                    try await vm.load(refresh: true, filters: filters, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: filters) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, filters: filters, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
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
        filters: TransactionFilters(),
        chartType: .earningsAndExpenses
    )
    .environment(AlertManager(handle: {_ in }))
}
