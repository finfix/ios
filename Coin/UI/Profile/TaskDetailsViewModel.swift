//
//  TaskDetailsViewModel.swift
//  Coin
//
//  Created by Илья on 10.05.2024.
//

import Foundation
import Factory
import GRDB

@Observable
class TasksDetailsViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    var task: SyncTask

    init(task: SyncTask) {
        self.task = task
    }

    /// Живая подписка на эту конкретную таску — обновляется сама (например, когда таска
    /// доисполнится в фоне на следующем executeDBTasks, tryCount/error поменяются без pull-to-refresh).
    func observeTask() -> AsyncValueObservation<SyncTask?> {
        service.taskManager.observeSyncTask(id: task.id)
    }

    func delete() async throws {
        try await service.taskManager.completeTasks(ids: [task.id])
    }

    func deleteAllTasks() async throws {
        try await service.taskManager.completeTasks()
    }

    /// Разбирает `fieldsJSON` таски и подгружает объект, к которому относится это
    /// действие синхронизации (созданный/обновлённый счёт, транзакцию, тег или группу счетов),
    /// чтобы можно было провалиться прямо в его экран редактирования.
    func fetchLinkedObjectRoute() async throws -> DeveloperObjectRoute? {
        struct EntityRef: Decodable { let id: UUID }
        guard let ref = try? JSONDecoder().decode(EntityRef.self, from: task.fieldsJSON) else {
            return nil
        }

        switch task.actionName {
        case .createAccount, .updateAccount:
            guard let account = try await service.getAccounts(ids: [ref.id]).first else { return nil }
            return .account(account)
        case .createTransaction, .updateTransaction:
            // У getTransactions нет фильтра по id, поэтому берём достаточно большой батч и ищем сами.
            let transactions = try await service.getTransactions(limit: 5000)
            guard let transaction = transactions.first(where: { $0.id == ref.id }) else { return nil }
            return .transaction(transaction)
        case .createTag, .updateTag:
            guard let tag = try await service.getTags().first(where: { $0.id == ref.id }) else { return nil }
            return .tag(tag)
        case .createAccountGroup, .updateAccountGroup:
            guard let group = try await service.getAccountGroups().first(where: { $0.id == ref.id }) else { return nil }
            return .accountGroup(group)
        case .createAccountBudget:
            // id в fieldsJSON — это id версии бюджета, а не счёта, к которому нужно перейти.
            guard let req = try? JSONDecoder().decode(CreateAccountBudgetReq.self, from: task.fieldsJSON),
                  let account = try await service.getAccounts(ids: [req.accountID]).first else { return nil }
            return .account(account)
        case .deleteTransaction, .deleteAccount, .deleteTag, .deleteAccountGroup, .updateUser:
            return nil
        }
    }
}

/// Экран, на который нужно перейти для конкретного объекта, связанного с таской синхронизации.
enum DeveloperObjectRoute: Hashable {
    case account(Account)
    case transaction(Transaction)
    case tag(Tag)
    case accountGroup(AccountGroup)
}
