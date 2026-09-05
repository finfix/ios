//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Две круглые "монетки" счетов (списание/пополнение) со стрелкой перетекания денег между ними
/// и встроенным (не модальным) списком выбора, раскрывающимся под ними.
struct TransferAccountsSelector: View {
    var fromTitle: String
    @Binding var accountFrom: Account
    var accountsFrom: [Account]
    var displayedBalanceFrom: Decimal?
    @Binding var isFromPickerShowing: Bool

    var toTitle: String
    @Binding var accountTo: Account
    var accountsTo: [Account]
    var displayedBalanceTo: Decimal?
    @Binding var isToPickerShowing: Bool

    var accountGroup: AccountGroup
    var onAccountChanged: () -> Void = {}

    @State private var drillParentFrom: Account?
    @State private var drillParentTo: Account?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                AccountSelectorField(
                    title: fromTitle,
                    account: accountFrom,
                    displayedBalance: displayedBalanceFrom,
                    isExpanded: isFromPickerShowing,
                    accountGroup: accountGroup,
                    onTap: toggleFrom,
                    onAccountChanged: onAccountChanged
                )
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                AccountSelectorField(
                    title: toTitle,
                    account: accountTo,
                    displayedBalance: displayedBalanceTo,
                    isExpanded: isToPickerShowing,
                    accountGroup: accountGroup,
                    onTap: toggleTo,
                    onAccountChanged: onAccountChanged
                )
            }
            if isFromPickerShowing {
                AccountInlinePicker(
                    accounts: accountsFrom,
                    selected: $accountFrom,
                    drillParent: $drillParentFrom,
                    onSelect: { isFromPickerShowing = false },
                    accountGroup: accountGroup,
                    onAccountChanged: onAccountChanged
                )
            }
            if isToPickerShowing {
                AccountInlinePicker(
                    accounts: accountsTo,
                    selected: $accountTo,
                    drillParent: $drillParentTo,
                    onSelect: { isToPickerShowing = false },
                    accountGroup: accountGroup,
                    onAccountChanged: onAccountChanged
                )
            }
        }
    }

    private func toggleFrom() {
        if isFromPickerShowing {
            isFromPickerShowing = false
            return
        }
        isFromPickerShowing = true
        isToPickerShowing = false
        drillParentFrom = accountsFrom.first { $0.childrenAccounts.contains { $0.id == accountFrom.id } }
    }

    private func toggleTo() {
        if isToPickerShowing {
            isToPickerShowing = false
            return
        }
        isToPickerShowing = true
        isFromPickerShowing = false
        drillParentTo = accountsTo.first { $0.childrenAccounts.contains { $0.id == accountTo.id } }
    }
}
