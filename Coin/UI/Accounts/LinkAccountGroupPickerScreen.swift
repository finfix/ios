//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import Factory

/// Первый шаг связи "счёт-мост" — выбор ГРУППЫ счетов (без текущей: мост всегда пересекает
/// границу группы, связывать со счётом собственной же группы бессмысленно). Обычный список, не
/// кружки — группы, в отличие от счетов, тут не про "коснитесь", а про явный выбор одной из.
struct LinkAccountGroupPickerScreen: View {
    let accountGroups: [AccountGroup]
    let allAccountsGrouped: [Account]
    let currentAccount: Account
    @Binding var linkedAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(accountGroups) { group in
            NavigationLink(group.name) {
                LinkAccountPickerScreen(
                    accounts: allAccountsGrouped.filter { $0.accountGroup.id == group.id },
                    currentAccount: currentAccount,
                    linkedAccountID: $linkedAccountID
                )
            }
        }
        .navigationTitle("Выбор группы счетов")
        // Экран выбора счёта (следующий шаг) закрывает СЕБЯ через dismiss() при выборе — этот
        // экран реагирует на тот же сигнал (linkedAccountID стал не nil) и закрывает СЕБЯ тоже.
        // Каждый шаг убирает только себя, поэтому не важно, на какой реальной глубине стека
        // (относительно EditAccount) сейчас находится вся цепочка — в отличие от подсчёта
        // "сколько уровней снять" вручную (path.path.removeLast(N)), который легко разъезжается
        // с реальной глубиной, если экран открыт не там, где предполагалось.
        .onChange(of: linkedAccountID) { _, newValue in
            if newValue != nil { dismiss() }
        }
    }
}
