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
    
    @Environment(AlertManager.self) private var alert
    @State private var vm: TransactionsListViewModel = TransactionsListViewModel()
    
    var filters: TransactionFilters
    
    @Environment(PathSharedState.self) var path
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    init(
        filters: TransactionFilters
    ) {
        self.filters = filters
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(zip(vm.transactions.indices, vm.transactions)), id: \.0) { i, transaction in
                VStack(spacing: 0) {
                    Group {
                        if i == 0 || vm.transactions[i-1].dateTransaction != vm.transactions[i].dateTransaction {
                            HStack {
                                Text(transaction.dateTransaction.formatted(date: .complete, time: .omitted).uppercased())
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 30)
                                    .padding(.bottom, 10)
                                    .padding(.horizontal, 10)
                                Spacer()
                            }
                            Divider()
                        }
                    }
                    VStack(spacing: 0) {
                        NavigationLink(value: TransactionsListRoute.editTransaction(transaction)) {
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                        }
                        .padding(.horizontal)
                        .frame(minHeight: 55)
                        .buttonStyle(.plain)
                        Divider()
                    }
                    .background(Color(.systemGray6))
                    //                .onDelete {
                    //                    for i in $0.makeIterator() {
                    //                        Task {
                    //                            do {
                    //                                try await vm.deleteTransaction(vm.groupedTransactionByDate[date]![i])
                    //                            } catch {
                    //                                alert(error)
                    //                            }
                    //                        }
                    //                    }
                    //                }
                }
            }
        }
        .task {
            do {
                try await vm.load(filters: filters)
            } catch {
                alert(error)
            }
        }
        .onChange(of: filters) { _, _ in
            Task {
                do {
                    try await vm.load(filters: filters)
                } catch {
                    alert(error)
                }
            }
        }
        .navigationTitle("Транзакции")
    }
}

#Preview {
    TransactionsList(
        filters: TransactionFilters()
    )
    .environment(AlertManager(handle: {_ in }))
}
