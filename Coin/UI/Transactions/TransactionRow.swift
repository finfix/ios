//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct TransactionRow: View {
        
    @State var transaction: Transaction
    @Query var accountGroups: [AccountGroup]
    @Query var accounts: [Account]
    
    var accountGroupsMap: [UInt32: AccountGroup] {
        Dictionary(uniqueKeysWithValues: accountGroups.map{ ($0.id, $0) })
    }
    
    var accountsMap: [UInt32: Account] {
        Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
    }
    
    var prefix: String {
        switch transaction.type {
        case .income: return "+ "
        case .consumption: return "- "
        default: return ""
        }
    }
    
    let currencies = Currencies.symbols
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if transaction.type != .balancing {
                    HStack {
                        Text(transaction.accountFrom?.name ?? "Недоступный счет")
                        Text(currencies[transaction.accountFrom?.currency ?? ""] ?? "")
                            .foregroundColor(.secondary)
                        Text(accountGroupsMap[transaction.accountFrom?.accountGroupID ?? 0]?.name ?? "" )
                            .foregroundColor(.secondary)
                    }
                    .font(.footnote)
                }
                HStack {
                    Text(transaction.accountTo?.name ?? "Недоступный счет")
                    Text(currencies[transaction.accountTo?.currency ?? "USD"] ?? "")
                        .foregroundColor(.secondary)
                    Text(accountGroupsMap[transaction.accountTo?.accountGroupID ?? 0]?.name ?? "" )
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                if transaction.amountFrom != transaction.amountTo {
                    Text(prefix + CurrencyFormatter().string(number: transaction.amountFrom, currency: transaction.accountFrom?.currency ?? "USD"))
                        .font(.footnote)
                }
                Text(prefix + CurrencyFormatter().string(number: transaction.amountTo, currency: transaction.accountTo?.currency ?? "USD"))
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
    TransactionRow(transaction: Transaction())
}
