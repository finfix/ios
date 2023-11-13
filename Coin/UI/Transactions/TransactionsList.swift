//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import Charts

struct TransactionsList: View {
    
    @Environment(ModelData.self) var modelData
    
    @State var showCreate = false
    @State var searchText = ""
    
    var groupedTransactionByDate: [Date : [Transaction]] {
        Dictionary(grouping: modelData.transactions, by: { $0.dateTransaction })
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date, style: .date).font(.headline)) {
                        ForEach (groupedTransactionByDate[date] ?? []) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                        .onDelete {
                            for i in $0.makeIterator() {
                                deleteTransaction(id: groupedTransactionByDate[date]![i].id)
                            }
                        }
                    }
                }
                Text("Идет загрузка...")
                    .onAppear {
                        modelData.getTransactions(offset: UInt32(modelData.transactions.count))
                    }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .listStyle(.grouped)
        }
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

#Preview {
    TransactionsList()
}
