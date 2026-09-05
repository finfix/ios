//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

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
    /// Мой счёт-получатель (targetAccountID) — показывается прямо в строке списка, чтобы сразу
    /// было видно, к какому СВОЕМУ счёту довносится сумма, не дожидаясь перехода на экран выбора
    /// (сама транзакция-инициатор — из ДРУГОЙ группы счетов, и это легко перепутать).
    var resolvedTargetAccounts: [UUID: Account] = [:]

    /// Только переносы, где меня ждут: мой счёт-получатель (targetAccountID) лежит в ВЫБРАННОЙ
    /// группе. Намеренно НЕ показываем здесь переносы, где я источник (accountGroupID совпадает
    /// с этой группой) — это уведомление для того, кому нужно ДЕЙСТВОВАТЬ (довнести), а не для
    /// того, кто уже знает, что сам создал перенос.
    func observeTransfers() async throws -> AsyncValueObservation<[PendingLinkedTransfer]> {
        let myAccountIDs = try await service.getAccounts(accountGroups: [accountGroup]).map(\.id)
        pendingLinkedTransfersLogger.debug("observeTransfers: accountGroup=\(self.accountGroup.name, privacy: .public) (\(self.accountGroup.id.uuidString, privacy: .public)) myAccountIDs=\(myAccountIDs.map { $0.uuidString.prefix(8).description }, privacy: .public)")
        return service.observePendingLinkedTransfers(accountGroups: [], myAccountIDs: myAccountIDs)
    }

    @MainActor
    func apply(_ transfers: [PendingLinkedTransfer]) {
        pendingLinkedTransfersLogger.debug("apply: raw=\(transfers.count) pending=\(transfers.filter { $0.status == .pending }.count) for accountGroup=\(self.accountGroup.name, privacy: .public)")
        self.transfers = transfers.filter { $0.status == .pending }
        for transfer in self.transfers where resolvedTransactions[transfer.id] == nil {
            Task { await resolveTransaction(for: transfer) }
        }
        for transfer in self.transfers where resolvedTargetAccounts[transfer.id] == nil {
            Task { await resolveTargetAccount(for: transfer) }
        }
    }

    @MainActor
    private func resolveTransaction(for transfer: PendingLinkedTransfer) async {
        guard resolvedTransactions[transfer.id] == nil else { return }
        guard let transaction = try? await service.getTransactions(ids: [transfer.sourceTransactionID]).first else { return }
        resolvedTransactions[transfer.id] = transaction
    }

    @MainActor
    private func resolveTargetAccount(for transfer: PendingLinkedTransfer) async {
        guard resolvedTargetAccounts[transfer.id] == nil else { return }
        guard let account = try? await service.getAccounts(ids: [transfer.targetAccountID]).first else { return }
        resolvedTargetAccounts[transfer.id] = account
    }

    func ignore(_ transfer: PendingLinkedTransfer) async throws {
        try await service.ignoreLinkedTransfer(transfer)
    }
}
