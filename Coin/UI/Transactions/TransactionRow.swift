//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct TransactionRow: View {
    
    @Environment(ModelData.self) var modelData
    
    @State var transaction: Transaction
    
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
                Text(String(format: transaction.type == .consumption ? "- %.2f" :
                                transaction.type == .income ? "+ %.2f" :
                                "%.2f",
                                transaction.amountTo))
                if transaction.note != "" {
                    Text(transaction.note)
                        .font(.footnote)
                }
            }
        }
        .padding()
    }
}

#Preview {
    TransactionRow(transaction: ModelData().transactions[0])
}
