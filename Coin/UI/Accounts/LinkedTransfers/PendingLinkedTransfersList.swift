//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

let pendingLinkedTransfersLogger = Logger(subsystem: "Coin", category: "PendingLinkedTransfers")





struct PendingLinkedTransfersList: View {
    @State private var vm: PendingLinkedTransfersViewModel
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) private var path

    init(accountGroup: AccountGroup) {
        vm = PendingLinkedTransfersViewModel(accountGroup: accountGroup)
    }

    /// Переносы, для которых уже резолвилась транзакция-инициатор, сгруппированные по дню —
    /// тот же принцип, что и TransactionsList.transactionItems/isNewSection, только тут список
    /// короткий и без пагинации, так что группировку проще держать прямо в body.
    private var groupedByDay: [(day: Date, items: [(transfer: PendingLinkedTransfer, transaction: Transaction)])] {
        let resolved = vm.transfers.compactMap { transfer -> (PendingLinkedTransfer, Transaction)? in
            guard let transaction = vm.resolvedTransactions[transfer.id] else { return nil }
            return (transfer, transaction)
        }
        let grouped = Dictionary(grouping: resolved) { $0.1.dateTransaction.stripTime() }
        return grouped
            .map { (day: $0.key, items: $0.value.sorted { $0.1.dateTransaction > $1.1.dateTransaction }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            if vm.transfers.isEmpty {
                Text("Нет переносов, ожидающих довнесения")
                    .foregroundStyle(.secondary)
            }
            ForEach(groupedByDay, id: \.day) { section in
                Section {
                    ForEach(section.items, id: \.transfer.id) { item in
                        Button {
                            path.path.append(PendingLinkedTransfersRoute.completeLinkedTransfer(item.transfer))
                        } label: {
                            PendingLinkedTransferRow(transaction: item.transaction, targetAccount: vm.resolvedTargetAccounts[item.transfer.id])
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Не переносить", role: .destructive) {
                                Task {
                                    do {
                                        try await vm.ignore(item.transfer)
                                    } catch {
                                        alert.error(error)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text(section.day.formatted(date: .complete, time: .omitted).uppercased())
                }
            }
        }
        .navigationTitle("Переносы")
        .task {
            do {
                for try await transfers in try await vm.observeTransfers() {
                    vm.apply(transfers)
                }
            } catch {
                alert.error(error)
            }
        }
    }
}

