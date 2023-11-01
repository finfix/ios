//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import SwiftData

struct TransactionsList: View {
    var groupedTransactionByDate: [Date : [Transaction]]
    
    var body: some View {
        List {
            ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(groupedTransactionByDate[date]!) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .onDelete {
                        for i in $0.makeIterator() {
                            deleteTransaction(id: groupedTransactionByDate[date]![i].id)
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
    }
    
    func deleteTransaction(id: UInt32) {
        Task {
            do {
                try await TransactionAPI().DeleteTransaction(req: DeleteTransactionReq(id: id))
            } catch {
                debugLog(error)
            }
        }
    }
}

struct TransactionSubView: View {
    
    @Query(sort: [
        SortDescriptor(\Transaction.dateTransaction, order: .reverse)
    ]) var transactions: [Transaction]
    
    var groupedTransactionByDate: [Date : [Transaction]] {
        print("Группируем транзакции")
        return Dictionary(grouping: transactions, by: { $0.dateTransaction })
    }
    
    init(searchString: String, dateFrom: Date, accountID: UInt32?) {
        _transactions = Query(filter: #Predicate {
            (searchString.isEmpty ? true : $0.note.localizedStandardContains(searchString)) &&
            $0.dateTransaction >= dateFrom &&
            (accountID == nil ? true : ($0.accountFromID == accountID || $0.accountToID == accountID))
        })
    }
    
    var body: some View {
        TransactionsList(groupedTransactionByDate: groupedTransactionByDate)
    }
}

struct TransactionsView: View {
    
    @State private var sortOrder = SortDescriptor(\Transaction.dateTransaction, order: .reverse)
    @State private var searchText = ""
    @State var dateFrom = Date()
    @State var accountID: UInt32?
    
    var body: some View {
        NavigationStack {
            TransactionSubView(searchString: searchText, dateFrom: dateFrom)
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem {
                        Menu {
                            DatePicker("Дата транзакции", selection: $dateFrom, displayedComponents: .date)
                        } label: {
                            Image(systemName: "calendar")
                        }
                    }
                }
        }
    }
}


#Preview {
    TransactionsView()
}
