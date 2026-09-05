//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Встроенный (не модальный) горизонтальный список выбора счёта в стиле главного экрана:
/// на верхнем уровне — все счета, тап по родительскому счёту показывает его дочерние счета
/// (и кружок возврата на уровень выше первым в ленте), тап по обычному счёту выбирает его
/// и закрывает список. Текущий выбранный счёт обведён рамкой.
struct AccountInlinePicker: View {
    var accounts: [Account]
    @Binding var selected: Account
    @Binding var drillParent: Account?
    var onSelect: () -> Void
    var accountGroup: AccountGroup
    var onAccountChanged: () -> Void = {}

    private var currentList: [Account] {
        drillParent?.childrenAccounts ?? accounts
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                if let parent = drillParent {
                    Button {
                        drillParent = nil
                    } label: {
                        VStack(spacing: 4) {
                            Text("Назад")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Circle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: "arrow.uturn.left")
                                        .foregroundStyle(.secondary)
                                }
                            Text(parent.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 70)
                    }
                    .buttonStyle(.plain)
                }
                ForEach(currentList) { account in
                    AccountInlinePickerRow(
                        account: account,
                        isHighlighted: isHighlighted(account),
                        accountGroup: accountGroup,
                        onTap: {
                            if account.isParent {
                                drillParent = account
                            } else {
                                selected = account
                                drillParent = nil
                                onSelect()
                            }
                        },
                        onAccountChanged: onAccountChanged
                    )
                }
                CreateAccountButton(
                    accountType: newAccountType,
                    accountGroup: accountGroup,
                    parentAccountID: drillParent?.id,
                    onAccountChanged: onAccountChanged
                )
            }
            .padding(.vertical, 4)
        }
    }

    /// Отмечаем сам выбранный счёт, а для родителя — если выбранный счёт лежит внутри него.
    private func isHighlighted(_ account: Account) -> Bool {
        selected.id == account.id || account.childrenAccounts.contains { $0.id == selected.id }
    }

    private var newAccountType: AccountType {
        drillParent?.type ?? accounts.first?.type ?? .regular
    }
}
