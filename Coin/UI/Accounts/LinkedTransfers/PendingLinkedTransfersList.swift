//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

private let logger = Logger(subsystem: "Coin", category: "PendingLinkedTransfers")

enum PendingLinkedTransfersRoute: Hashable {
    case list
    case selectAccount(PendingLinkedTransfer)
}

@Observable
class PendingLinkedTransfersViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    let accountGroup: AccountGroup

    init(accountGroup: AccountGroup) {
        self.accountGroup = accountGroup
    }

    var transfers: [PendingLinkedTransfer] = []
    /// Разрешённая на конкретный перенос транзакция-инициатор — резолвится лениво в момент показа строки.
    var resolvedTransactions: [UUID: Transaction] = [:]

    /// Только переносы, где меня ждут: мой счёт-получатель (targetAccountID) лежит в ВЫБРАННОЙ
    /// группе. Намеренно НЕ показываем здесь переносы, где я источник (accountGroupID совпадает
    /// с этой группой) — это уведомление для того, кому нужно ДЕЙСТВОВАТЬ (довнести), а не для
    /// того, кто уже знает, что сам создал перенос.
    func observeTransfers() async throws -> AsyncValueObservation<[PendingLinkedTransfer]> {
        let myAccountIDs = try await service.getAccounts(accountGroups: [accountGroup]).map(\.id)
        logger.debug("observeTransfers: accountGroup=\(self.accountGroup.name, privacy: .public) (\(self.accountGroup.id.uuidString, privacy: .public)) myAccountIDs=\(myAccountIDs.map { $0.uuidString.prefix(8).description }, privacy: .public)")
        return service.observePendingLinkedTransfers(accountGroups: [], myAccountIDs: myAccountIDs)
    }

    @MainActor
    func apply(_ transfers: [PendingLinkedTransfer]) {
        logger.debug("apply: raw=\(transfers.count) pending=\(transfers.filter { $0.status == .pending }.count) for accountGroup=\(self.accountGroup.name, privacy: .public)")
        self.transfers = transfers.filter { $0.status == .pending }
    }

    func resolveTransaction(for transfer: PendingLinkedTransfer) async {
        guard resolvedTransactions[transfer.id] == nil else { return }
        guard let transaction = try? await service.getTransactions(ids: [transfer.sourceTransactionID]).first else { return }
        resolvedTransactions[transfer.id] = transaction
    }

    func ignore(_ transfer: PendingLinkedTransfer) async throws {
        try await service.ignoreLinkedTransfer(transfer)
    }
}

/// Кнопка-уведомление в тулбаре AccountCirclesView — видна только если есть хотя бы один
/// pending-перенос, ведёт на PendingLinkedTransfersList.
struct PendingLinkedTransfersBadge: View {
    @State private var vm: PendingLinkedTransfersViewModel
    @Environment(PathSharedState.self) private var path

    init(accountGroup: AccountGroup) {
        vm = PendingLinkedTransfersViewModel(accountGroup: accountGroup)
    }

    var body: some View {
        Group {
            if !vm.transfers.isEmpty {
                Button {
                    path.path.append(PendingLinkedTransfersRoute.list)
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundStyle(.orange)
                        .overlay(alignment: .topTrailing) {
                            Text("\(vm.transfers.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Circle().fill(.red))
                                .offset(x: 8, y: -8)
                        }
                }
            }
        }
        .task {
            logger.debug("PendingLinkedTransfersBadge: .task запустился")
            do {
                for try await transfers in try await vm.observeTransfers() {
                    vm.apply(transfers)
                }
            } catch {
                logger.error("PendingLinkedTransfersBadge: \(String(describing: error), privacy: .public)")
            }
        }
    }
}

struct PendingLinkedTransfersList: View {
    @State private var vm: PendingLinkedTransfersViewModel
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) private var path

    init(accountGroup: AccountGroup) {
        vm = PendingLinkedTransfersViewModel(accountGroup: accountGroup)
    }

    var body: some View {
        List {
            if vm.transfers.isEmpty {
                Text("Нет переносов, ожидающих довнесения")
                    .foregroundStyle(.secondary)
            }
            ForEach(vm.transfers) { transfer in
                let transaction = vm.resolvedTransactions[transfer.id]
                Button {
                    path.path.append(PendingLinkedTransfersRoute.selectAccount(transfer))
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            if let transaction {
                                Text(CurrencyFormatter().string(number: transaction.amountFrom, currency: transaction.accountFrom.currency))
                                    .font(.headline)
                                Text(transaction.dateTransaction, format: .dateTime.day().month().year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Загрузка…")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .task {
                    await vm.resolveTransaction(for: transfer)
                }
                .swipeActions {
                    Button("Не переносить", role: .destructive) {
                        Task {
                            do {
                                try await vm.ignore(transfer)
                            } catch {
                                alert.error(error)
                            }
                        }
                    }
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
