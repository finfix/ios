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
    
    @State private var offsets = [CGSize](repeating: CGSize.zero, count: 100)

    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    init(
        filters: TransactionFilters
    ) {
        self.filters = filters
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(vm.transactionItems) { item in
                VStack(spacing: 0) {
                    Group {
                        if item.isNewSection {
                            HStack {
                                Text(item.transaction.dateTransaction.formatted(date: .complete, time: .omitted).uppercased())
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
                        NavigationLink(value: TransactionsListRoute.editTransaction(item.transaction)) {
                            TransactionRow(transaction: item.transaction)
                                .contentShape(Rectangle())
                        }
                        .padding(.horizontal)
                        .frame(minHeight: 55)
                        .buttonStyle(.plain)
                        Divider()
                    }
                    .background(Color(.systemGray6))
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
        filters: TransactionFilters(accountGroups: [])
    )
    .environment(AlertManager(handle: {_ in }))
}
