//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import Factory

/// Второй шаг — пикер счёта внутри уже выбранной группы, переиспользует общий
/// AccountCirclePicker (та же сетка, что на главном экране счетов). Деактивирует неподходящие
/// счета: сам счёт, уже связанные, другой валюты или несовместимого типа (см.
/// EditAccountViewModel.bridgeCompatibleType) — но не убирает их из сетки.
struct LinkAccountPickerScreen: View {
    let accounts: [Account]
    let currentAccount: Account
    @Binding var linkedAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AccountCirclePicker(
            title: "Связать со счётом",
            accounts: accounts,
            isDisabled: { candidate in
                candidate.id == currentAccount.id ||
                candidate.isParent ||
                candidate.linkedAccountID != nil ||
                candidate.currency != currentAccount.currency ||
                EditAccountViewModel.bridgeCompatibleType(for: currentAccount.type) != candidate.type
            }
        ) { account in
            linkedAccountID = account.id
            dismiss()
        }
    }
}
