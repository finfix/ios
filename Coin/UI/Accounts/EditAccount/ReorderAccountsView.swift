//
//  ReorderAccountsView.swift
//  Coin
//

import SwiftUI
import Factory

struct ReorderAccountsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AlertManager.self) private var alert

    @Injected(\.service) private var service

    @State private var accounts: [Account]

    init(accounts: [Account]) {
        _accounts = State(initialValue: accounts)
    }

    var body: some View {
        List {
            ForEach(accounts) { account in
                HStack {
                    Text(account.name)
                    Spacer()
                    Text(account.currency.symbol)
                        .foregroundStyle(.secondary)
                }
            }
            .onMove { from, to in
                accounts.move(fromOffsets: from, toOffset: to)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Порядок счетов")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    Task {
                        do {
                            try await service.reorderAccounts(accounts)
                        } catch {
                            alert.error(error)
                            return
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
