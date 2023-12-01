//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "TransactionList")

struct TransactionsView: View {
    
    @State private var sortOrder = SortDescriptor(\Transaction.dateTransaction, order: .reverse)
    @State private var searchText = ""
    @State var dateFrom: Date?
    
    @State var dateTo: Date?
    @State var accountID: UInt32?
    @State var isFilterOpen = false
    
    var body: some View {
        NavigationStack {
            TransactionsList(searchString: searchText, dateFrom: dateFrom, dateTo: dateTo, accountID: accountID)
                .navigationDestination(for: Transaction.self) { EditTransaction($0) }
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        // Фильтры
                        Button { isFilterOpen.toggle() } label: { Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle") }
                    }
                }
                .sheet(isPresented: $isFilterOpen) { TransactionFilterView(isShowing: $isFilterOpen, dateFrom: $dateFrom, dateTo: $dateTo) }
                .navigationTitle("Транзакции")
        }
    }
}

struct TransactionsList: View {
    
    @Environment(\.modelContext) var modelContext
    @Query(sort: [
        SortDescriptor(\Transaction.dateTransaction, order: .reverse)
    ]) var transactions: [Transaction]
        
    init(searchString: String = "", dateFrom: Date? = nil, dateTo: Date? = nil, accountID: UInt32? = nil) {
        logger.info("Фильтруем транзакции")
        _transactions = Query(filter: #Predicate {
            (searchString.isEmpty ? true : $0.note.localizedStandardContains(searchString)) &&
            (dateFrom == nil ? true : $0.dateTransaction >= dateFrom!) &&
            (dateTo == nil ? true : $0.dateTransaction <= dateTo!)
        })
    }
    
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
                modelContext.delete(transaction)
            } catch {
                showErrorAlert("\(error)")
                logger.error("\(error)")
            }
        }
    }
}

#Preview {
    TransactionsView()
        .modelContainer(previewContainer)
}
