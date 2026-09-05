//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Цвет-заглушка счёта по его типу (упрощённая версия палитры из AccountCircleItemCircle).
func accountTypeColor(_ type: AccountType) -> Color {
    switch type {
    case .balancing: return .yellow
    case .debt, .regular: return .orange
    case .expense: return .green
    case .earnings: return .blue
    }
}



/// Кружок счёта в стиле главного экрана (название сверху, иконка, баланс снизу).
/// По тапу вызывает `onTap` — открытие/закрытие списка выбора управляется снаружи.
/// Долгий тап (если счёт уже выбран) открывает редактирование этого счёта.
struct AccountSelectorField: View {
    var title: String
    var account: Account
    var displayedBalance: Decimal? = nil
    var isExpanded: Bool
    var accountGroup: AccountGroup
    var onTap: () -> Void
    var onAccountChanged: () -> Void = {}

    @State private var isEditingAccount = false

    private var isSelected: Bool {
        account.id != UUID(uuid: UUID_NULL)
    }

    private var balance: Decimal {
        displayedBalance ?? (account.isParent ? account.showingRemainder : account.remainder)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(isSelected ? account.name : title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isSelected ? .primary : .secondary)
            AccountIconCircle(account: account, diameter: 56)
                .opacity(isSelected ? 1 : 0.4)
                .overlay {
                    if isExpanded {
                        Circle().stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            Text(isSelected ? CurrencyFormatter(currency: account.currency, maximumFractionDigits: 7, withUnits: false).string(number: balance) : " ")
                .font(.caption)
                .foregroundStyle(balance < 0 ? .red : .primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // Долгий тап и обычный тап взаимоисключающие, чтобы при отпускании после долгого
        // тапа не срабатывал ещё и обычный тап (иначе он тут же закрывал/выбирал счёт).
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    if isSelected {
                        isEditingAccount = true
                    }
                }
                .exclusively(before: TapGesture().onEnded(onTap))
        )
        .sheet(isPresented: $isEditingAccount, onDismiss: onAccountChanged) {
            NavigationStack {
                EditAccount(account, selectedAccountGroup: accountGroup)
            }
        }
    }
}




