//
//  TransactionRow.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct TransactionRow: View {

    let transaction: TransactionListRowData

    var prefix: String {
        switch transaction.type {
        case .income: return "+ "
        case .consumption: return "- "
        case .balancing: return transaction.accountFromType == .balancing ? "+ " : "- "
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

    // Для балансировочных транзакций всегда показываем не-балансировочный счет
    var displayAccountName: String {
        transaction.accountFromType == .balancing ? transaction.accountToName : transaction.accountFromName
    }

    var displayAccountCurrency: Currency {
        transaction.accountFromType == .balancing ? transaction.accountToCurrency : transaction.accountFromCurrency
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if transaction.type != .balancing {
                    HStack {
                        Text(transaction.accountFromName)
                    }
                    .font(.footnote)
                }
                HStack {
                    Text(transaction.type == .balancing ? displayAccountName : transaction.accountToName)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                VStack(alignment: .trailing) {
                    if transaction.amountFrom != transaction.amountTo && transaction.type != .balancing {
                        Text(prefix + CurrencyFormatter(maximumFractionDigits: 7).string(number: transaction.amountFrom, currency: transaction.accountFromCurrency, withUnits: false))
                            .font(.footnote)
                    }
                    Text(prefix + CurrencyFormatter(maximumFractionDigits: 7).string(number: transaction.amountTo, currency: displayAccountCurrency, withUnits: false))
                }
                .foregroundStyle(color)
                if transaction.note != "" {
                    Text(transaction.note)
                        .font(.footnote)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    ForEach(transaction.tagNames, id: \.self) { tagName in
                        Text("#\(tagName)")
                            .font(.caption2)
                    }
                }
            }
            .padding(.vertical, 10)
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.footnote)
                .padding(.leading, 10)
        }
    }
}

#Preview {
    List {
        TransactionRow(
            transaction: TransactionListRowData(
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
        )
            .environment(AlertManager(handle: {_ in }))
    }
    .listStyle(.plain)
}
