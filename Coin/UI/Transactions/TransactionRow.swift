//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct TransactionRow: View {
        
    @State var transaction: Transaction
        
    var prefix: String {
        switch transaction.type {
        case .income, .balancing: return "+ "
        case .consumption: return "- "
        default: return ""
        }
    }
        
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading) {
                    if transaction.type != .balancing {
                        HStack {
                            Text(transaction.accountFrom?.name ?? "Недоступный счет")
                            Text(transaction.accountFrom?.currency?.symbol ?? "")
                                .foregroundColor(.secondary)
                            Text(transaction.accountFrom?.accountGroup?.name ?? "" )
                                .foregroundColor(.secondary)
                        }
                        .font(.footnote)
                    }
                    HStack {
                        Text(transaction.accountTo?.name ?? "Недоступный счет")
                        Text(transaction.accountTo?.currency?.symbol ?? "")
                            .foregroundColor(.secondary)
                        Text(transaction.accountTo?.accountGroup?.name ?? "" )
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    if transaction.amountFrom != transaction.amountTo && transaction.type != .balancing {
                        Text(prefix + CurrencyFormatter().string(number: transaction.amountFrom, currency: transaction.accountFrom?.currency))
                            .font(.footnote)
                    }
                    Text(prefix + CurrencyFormatter().string(number: transaction.amountTo, currency: transaction.accountTo?.currency))
                    if transaction.note != "" {
                        Text(transaction.note)
                            .font(.footnote)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        TransactionRow(transaction: Transaction())
    }
}
