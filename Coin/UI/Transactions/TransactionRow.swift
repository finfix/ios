//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct TransactionRow: View {
        
    let transaction: Transaction
        
    var prefix: String {
        switch transaction.type {
        case .income, .balancing: return "+ "
        case .consumption: return "- "
        default: return ""
        }
    }
    
    var color: Color {
        switch transaction.type {
        case .income: .green
        case .consumption: .red
        case .balancing: .secondary
        default: .primary
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if transaction.type != .balancing {
                    HStack {
                        Text(transaction.accountFrom.name)
                    }
                    .font(.footnote)
                }
                HStack {
                    Text(transaction.accountTo.name)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                VStack(alignment: .trailing) {
                    if transaction.amountFrom != transaction.amountTo && transaction.type != .balancing {
                        Text(prefix + CurrencyFormatter().string(number: transaction.amountFrom, currency: transaction.accountFrom.currency, withUnits: false))
                            .font(.footnote)
                    }
                    Text(prefix + CurrencyFormatter().string(number: transaction.amountTo, currency: transaction.accountTo.currency, withUnits: false))
                }
                .foregroundStyle(color)
                if transaction.note != "" {
                    Text(transaction.note)
                        .font(.footnote)
                        .lineLimit(2)
                }
                HStack {
                    ForEach(transaction.tags) { tag in
                        Text("#\(tag.name)")
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        TransactionRow(
            transaction: 
                Transaction(
                    amountFrom: 1000,
                    amountTo: 10,
                    dateTransaction: Date.now.stripTime(),
                    isExecuted: true,
                    note: "Заметка\nВторая линия\nТретья линия",
                    type: .consumption,
                    datetimeCreate: Date.now,
                    accountFrom:
                        Account(
                            name: "Обычный счет",
                            currency:
                                Currency(
                                    code: "₽"
                                )
                        ),
                    accountTo:
                        Account(
                            name: "Счет расхода",
                            currency:
                                Currency(
                                    code: "$"
                                )
                        ),
                    tags: [
                        Tag(name: "tag1"),
                        Tag(name: "tag2"),
                        Tag(name: "tag3 very very long text")
                    ]
                )
        )
            .environment(AlertManager(handle: {_ in }))
    }
    .listStyle(.plain)
}
