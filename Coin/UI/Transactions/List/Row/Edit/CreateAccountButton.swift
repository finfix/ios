//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Кружок "+" в конце ленты для создания нового счёта прямо из выбора счёта транзакции.
/// Если открыт внутри родительского счёта, новый счёт создаётся его дочерним —
/// это включает уже существующую в EditAccount фичу наследования названия от родителя.
struct CreateAccountButton: View {
    var accountType: AccountType
    var accountGroup: AccountGroup
    var parentAccountID: UUID?
    var onAccountChanged: () -> Void = {}

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(spacing: 4) {
                Text(" ")
                    .font(.caption)
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                Text("Счёт")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented, onDismiss: onAccountChanged) {
            NavigationStack {
                EditAccount(
                    accountType: accountType,
                    accountGroup: accountGroup,
                    initialParentAccountID: parentAccountID
                )
            }
        }
    }
}
