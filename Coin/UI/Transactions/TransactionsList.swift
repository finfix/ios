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
    @Environment(AppSettings.self) var appSettings
    
    @State var showCreate = false
    
    var groupedTransactionByDate: [Date : [Transaction]] {
        Dictionary(grouping: modelData.transactions, by: { $0.dateTransaction })
    }
    
    var body: some View {
        NavigationStack {
                // Список транзакций
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
            // Верхняя панель
                .navigationBarItems(trailing: Button{
                    modelData.getTransactions()
                } label: {
                    Image(systemName: "arrow.clockwise")
                })
            .navigationBarTitle("Транзакции")
            .navigationBarBackButtonHidden(true)
        }
    }
    
    func deleteTransaction(id: UInt32) {
        TransactionAPI().DeleteTransaction(req: DeleteTransactionRequest(id: id)) { error in
            if let err = error {
                appSettings.showErrorAlert(error: err)
            }
        }
    }
}

#Preview {
    TransactionsList()
}
