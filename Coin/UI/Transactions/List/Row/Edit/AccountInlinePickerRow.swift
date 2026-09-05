//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Строка счёта в горизонтальной ленте: тап выбирает/раскрывает счёт,
/// долгий тап (если счёт уже существует) открывает его редактирование.
struct AccountInlinePickerRow: View {
    var account: Account
    var isHighlighted: Bool
    var accountGroup: AccountGroup
    var onTap: () -> Void
    var onAccountChanged: () -> Void = {}

    @State private var isEditingAccount = false

    var body: some View {
        VStack(spacing: 4) {
            Text(account.name)
                .font(.caption)
                .lineLimit(1)
            AccountIconCircle(account: account, diameter: 56)
                .overlay {
                    if isHighlighted {
                        Circle().stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            Text(CurrencyFormatter(currency: account.currency, maximumFractionDigits: 7, withUnits: false).string(
                number: account.isParent ? account.showingRemainder : account.remainder
            ))
            .font(.caption)
            .lineLimit(1)
        }
        .frame(width: 70)
        .contentShape(Rectangle())
        // Долгий тап и обычный тап взаимоисключающие — иначе при отпускании после
        // долгого тапа сразу срабатывал обычный тап и закрывал только что открытое окно.
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in isEditingAccount = true }
                .exclusively(before: TapGesture().onEnded(onTap))
        )
        .sheet(isPresented: $isEditingAccount, onDismiss: onAccountChanged) {
            NavigationStack {
                EditAccount(account, selectedAccountGroup: accountGroup)
            }
        }
    }
}
