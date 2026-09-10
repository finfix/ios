//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import Factory

/// Пикер родительского счёта — тоже переиспользует AccountCirclePicker, но с
/// selectsParents: true (тап по родителю сразу выбирает его, а не открывает панель детей) и
/// деактивированными не-родительскими счетами и родителями другого типа (дочерний счёт может
/// принадлежать только родителю своего же типа).
struct ParentAccountPickerScreen: View {
    let accounts: [Account]
    let childType: AccountType
    @Binding var parentAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Button("Не выбрано") {
                parentAccountID = nil
                dismiss()
            }
            .padding()
            Divider()
            AccountCirclePicker(
                title: "Родительский счёт",
                accounts: accounts,
                selectsParents: true,
                isDisabled: { !$0.isParent || $0.type != childType }
            ) { account in
                parentAccountID = account.id
                dismiss()
            }
        }
    }
}
