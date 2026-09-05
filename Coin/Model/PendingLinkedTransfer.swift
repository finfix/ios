//
//  PendingLinkedTransfer.swift
//  Coin
//

import Foundation

/// Требование довнесения транзакции через счёт-мост (см. Account.linkedAccountID). Плоская
/// структура-связка — sourceAccountID/targetAccountID/accountGroupID хранятся как id, а не
/// резолвятся в объекты автоматически: targetAccountID может быть моим счётом (я получатель) или
/// нет (я источник), в зависимости от того, с чьей стороны я смотрю на запись.
struct PendingLinkedTransfer: Identifiable, Hashable {
    var id: UUID
    var status: PendingLinkedTransferStatus
    var sourceTransactionID: UUID
    var sourceAccountID: UUID
    var targetAccountID: UUID
    var accountGroupID: UUID

    init(
        id: UUID = UUID(),
        status: PendingLinkedTransferStatus = .pending,
        sourceTransactionID: UUID = UUID(),
        sourceAccountID: UUID = UUID(),
        targetAccountID: UUID = UUID(),
        accountGroupID: UUID = UUID()
    ) {
        self.id = id
        self.status = status
        self.sourceTransactionID = sourceTransactionID
        self.sourceAccountID = sourceAccountID
        self.targetAccountID = targetAccountID
        self.accountGroupID = accountGroupID
    }

    init(_ dbModel: PendingLinkedTransferDB) {
        self.id = dbModel.id!
        self.status = dbModel.status
        self.sourceTransactionID = dbModel.sourceTransactionID
        self.sourceAccountID = dbModel.sourceAccountID
        self.targetAccountID = dbModel.targetAccountID
        self.accountGroupID = dbModel.accountGroupID
    }

    static func convertFromDBModel(_ dbModels: [PendingLinkedTransferDB]) -> [PendingLinkedTransfer] {
        dbModels.map { PendingLinkedTransfer($0) }
    }

    /// Разрешает "куда идут деньги" для довносящей транзакции — общая логика для
    /// SelectAccountForTransfer (отдельный экран) и режима "коснитесь счёта" на главном экране
    /// счетов. Направление на моей стороне зеркалит направление у инициатора: если деньги
    /// ПРИШЛИ в счёт-мост там (он был accountTo), то у меня они продолжают путь ИЗ моста (мост —
    /// accountFrom), и наоборот. Возвращает nil, если выбранный счёт даёт недопустимую пару типов
    /// (см. EditAccount: только regular↔regular, expense↔earnings).
    func resolveCompletion(
        tappedAccount: Account,
        myBridgeAccount: Account,
        sourceTransaction: Transaction
    ) -> (type: TransactionType, accountFrom: Account, accountTo: Account)? {
        let bridgeIsSource = sourceTransaction.accountTo.id == sourceAccountID
        let accountFrom = bridgeIsSource ? myBridgeAccount : tappedAccount
        let accountTo = bridgeIsSource ? tappedAccount : myBridgeAccount

        switch true {
        case accountFrom.type == .earnings && accountTo.type == .regular: return (.income, accountFrom, accountTo)
        case accountFrom.type == .regular && accountTo.type == .regular: return (.transfer, accountFrom, accountTo)
        case accountFrom.type == .regular && accountTo.type == .expense: return (.consumption, accountFrom, accountTo)
        default: return nil
        }
    }
}

