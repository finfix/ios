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
    
    @State private var searchText = ""
    @State var dateFrom: Date? = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: Date.now)!
    
    @State var dateTo: Date?
    @State var accountID: UInt32?
    @State var isFilterOpen = false
    
    var body: some View {
        NavigationStack {
            TransactionsList()
                .navigationDestination(for: Transaction.self) { EditTransaction($0) }
                .searchable(text: $searchText)
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

struct TransactionsList: View {
    
    var transactions: [Transaction] = []
    
    var body: some View {
        let groupedTransactionByDate = Dictionary(grouping: transactions, by: { $0.dateTransaction })
        
        List {
            ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(groupedTransactionByDate[date]!) { transaction in
                        NavigationLink(value: transaction) {
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .onDelete {
                        for i in $0.makeIterator() {
                            deleteTransaction(groupedTransactionByDate[date]![i])
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        Task {
            do {
                try await TransactionAPI().DeleteTransaction(req: DeleteTransactionReq(id: transaction.id))
                switch transaction.type {
                case .transfer, .consumption:
                    transaction.accountFrom?.remainder += transaction.amountFrom
                    transaction.accountTo?.remainder -= transaction.amountTo
                case .income:
                    transaction.accountFrom?.remainder -= transaction.amountFrom
                    transaction.accountTo?.remainder -= transaction.amountTo
                case .balancing:
                    transaction.accountTo?.remainder -= transaction.amountTo
                }
            } catch {
                showErrorAlert("\(error)")
                logger.error("\(error)")
            }
        }
    }
}

#Preview {
    TransactionsView()
}
