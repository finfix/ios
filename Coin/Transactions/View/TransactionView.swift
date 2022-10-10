//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct TransactionView: View {
    
    /// Добавляем Network в качестве EnvironmentObject
    @EnvironmentObject var network: TransactionAPI
    
    var body: some View {
        NavigationView {
            List(network.transactions, id: \.id) { transaction in
                HStack {
                    VStack(alignment: .leading) {
                        Text(transaction.dateTransaction)
                        Text("\(transaction.accountFromID) -> \(transaction.accountToID)")
                            .font(.footnote)
                        
                        if transaction.amountTo == transaction.amountFrom {
                            Text(String(format: "%.2f", transaction.amountTo))
                                .font(.footnote)
                        } else {
                            Text(String(format: "%.2f", transaction.amountFrom) + " -> " + String(format: "%.2f", transaction.amountTo))
                                .font(.footnote)
                        }
                    }
                    Spacer()
                    if let note = transaction.note {
                        Text(note)
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .onAppear {
                network.getTransaction()
            }
        }
    }
}

struct Transaction_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
