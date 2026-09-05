//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

/// Отдельная view (а не inline-выражение в List) — иначе компилятор не справляется с выводом
/// типов внутри вложенного ForEach/Section/List (реальный краш type-checker'а на этом файле).
struct PendingLinkedTransferRow: View {
    let transaction: Transaction
    let targetAccount: Account?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TransactionRow(transaction: TransactionListRowData(transaction))
            if let targetAccount {
                Label("К счёту «\(targetAccount.name)»", systemImage: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
    }
}
