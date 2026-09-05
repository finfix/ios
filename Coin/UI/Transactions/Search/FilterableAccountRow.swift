//
//  SearchView.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import SwiftUI

/// Строка счёта в поиске фильтров — вместо отдельной секции "Исключить счета" (тот же счёт,
/// просто другое действие) прямо тут два действия: зелёный плюс добавляет в filters.accounts
/// (включить), красный минус — в filters.excludedAccounts (исключить). Выбранные счета (в любой
/// роли) пропадают из этого списка и появляются чипом в TransactionFiltersRowView — там же и
/// снимаются.
struct FilterableAccountRow: View {
    let account: Account
    let showAccountGroup: Bool
    let onInclude: () -> Void
    let onExclude: () -> Void

    var body: some View {
        HStack {
            HStack {
                if showAccountGroup {
                    Text(account.accountGroup.name)
                    Text("•")
                }
                if let parentAccount = account.parentAccount.account {
                    Text(parentAccount.name)
                    Text("•")
                }
                Text(account.name)
            }
            Spacer()
            Button(action: onInclude) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            Button(action: onExclude) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
