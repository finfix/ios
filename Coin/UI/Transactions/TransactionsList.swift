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
            }
            .listStyle(.grouped)
        }
    }
    
    func deleteTransaction(id: UInt32) {
        TransactionAPI().DeleteTransaction(req: DeleteTransactionRequest(id: id)) { error in
            if let err = error {
                showErrorAlert(error: err)
            }
        }
    }
}

#Preview {
    TransactionsList()
}
