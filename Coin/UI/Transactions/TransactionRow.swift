//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct TransactionRow: View {
        
    @State var showUpdate = false
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
    
    var accountFrom: Account {
        accountsMap[transaction.accountFromID] ?? Account(name: "Недоступный счет")
    }
    
    var accountTo: Account {
        accountsMap[transaction.accountToID] ?? Account(name: "Недоступный счет")
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if transaction.type != .balancing {
                    HStack {
                        Text(accountFrom.name)
                        Text(CurrencySymbols[accountFrom.currency] ?? "")
                            .foregroundColor(.secondary)
                        Text(accountGroupsMap[accountFrom.accountGroupID]?.name ?? "" )
                            .foregroundColor(.secondary)
                    }
                    .font(.footnote)
                }
                HStack {
                    Text(accountTo.name)
                    Text(CurrencySymbols[accountTo.currency] ?? "")
                        .foregroundColor(.secondary)
                    Text(accountGroupsMap[accountTo.accountGroupID]?.name ?? "" )
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                if transaction.amountFrom != transaction.amountTo {
                    Text(prefix + CurrencyFormatter().string(number: transaction.amountFrom, currency: accountFrom.currency))
                        .font(.footnote)
                }
                Text(prefix + CurrencyFormatter().string(number: transaction.amountTo, currency: accountTo.currency))
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
    TransactionRow(transaction: Transaction())
}
