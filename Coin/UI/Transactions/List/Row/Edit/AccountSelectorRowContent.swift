//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Строка счёта: иконка, название, валюта и баланс (или прогнозируемый баланс, если передан).
struct AccountSelectorRowContent: View {
    var account: Account
    var balanceOverride: Decimal? = nil
    var showChevron: Bool = false

    private var balance: Decimal {
        balanceOverride ?? (account.isParent ? account.showingRemainder : account.remainder)
    }

    var body: some View {
        HStack {
            AccountIconCircle(account: account)
            VStack(alignment: .leading, spacing: 1) {
                Text(account.name)
                    .lineLimit(1)
                Text(account.currency.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter(currency: account.currency, maximumFractionDigits: 7, withUnits: false).string(number: balance))
                .foregroundStyle(balance < 0 ? .red : .primary)
                .lineLimit(1)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
