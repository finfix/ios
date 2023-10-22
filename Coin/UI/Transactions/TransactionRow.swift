//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct TransactionRow: View {
    
    @Environment(ModelData.self) var modelData
    
    @State var showUpdate = false
    @State var transaction: Transaction
    
    var prefix: String {
        switch transaction.type {
        case .income: return "+ "
        case .consumption: return "- "
        default: return ""
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if transaction.type != .balancing {
                    Text(modelData.accountsMap[transaction.accountFromID]?.name ?? "Нет счета")
                        .font(.footnote)
                }
                Text(modelData.accountsMap[transaction.accountToID]?.name ?? "Нет счета")
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(prefix + CurrencyFormatter().string(number: transaction.amountTo, currency: modelData.accountsMap[transaction.accountToID]?.currency))
                if transaction.note != "" {
                    Text(transaction.note)
                        .font(.footnote)
                }
            }
        }
        .onTapGesture {
            showUpdate = true
        }
        .padding()
        .navigationDestination(isPresented: $showUpdate) {
            UpdateTransaction(isUpdateOpen: $showUpdate, transaction: transaction)
        }
    }
}

#Preview {
    TransactionRow(transaction: ModelData().transactions[0])
}
