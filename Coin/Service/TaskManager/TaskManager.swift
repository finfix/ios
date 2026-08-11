//
//  TaskManager.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "Coin", category: "TaskManager")

@Observable
class TaskManager {
    
    init(repository: Repository, apiManager: APIManager) {
        self.repository = repository
        self.apiManager = apiManager
    }
    
    let repository: Repository
    let apiManager: APIManager
    var syncInProgress = false

    // MARK: - Отладочная информация об инкрементальной синхронизации (для DeveloperTools)
    private(set) var incrementalSyncInProgress = false
    private(set) var lastIncrementalSyncStartedAt: Date?
    private(set) var lastIncrementalSyncFinishedAt: Date?
    private(set) var lastIncrementalSyncError: String?
    /// Человекочитаемая сводка последнего успешного incrementalSync — например
    /// "изменений нет" или "3 транзакции, 1 счёт".
    private(set) var lastIncrementalSyncSummary: String?
    private(set) var lastConfirmSyncConflict: Date?

    // Обрабатывает невыполненные таски волнами: на каждой волне выполняются параллельно
    // только те таски, все зависимости которых уже обработаны (см. createTask). Связанные
    // таски (та же сущность или явная межсущностная зависимость) никогда не окажутся в одной
    // волне — зависимая таска становится "готовой" только после того, как её зависимость
    // покидает remaining (выполнилась либо провалилась).
    func executeDBTasks() async throws {

        if syncInProgress {
            logger.warning("Синхронизация в процессе, ждем ответа от сервера")
            return
        }

        syncInProgress = true
        defer { syncInProgress = false }

        var remaining = try await repository.getSyncTasks()
        guard !remaining.isEmpty else { return }
        logger.log("Количество тасок: \(remaining.count)")

        // Таски, чья зависимость в этом цикле провалилась — сама она (и всё, что от неё
        // зависит) не выполняется в этом проходе, попробуем в следующий раз.
        var blockedIDs: Set<UUID> = []

        while !remaining.isEmpty {
            let remainingIDs = Set(remaining.map(\.id))

            let ready = remaining.filter { task in
                task.dependsOnTaskIDs.allSatisfy { !remainingIDs.contains($0) && !blockedIDs.contains($0) }
            }

            guard !ready.isEmpty else {
                logger.warning("Есть незавершённые таски (\(remaining.count)), но ни одна не готова к выполнению — отложены до следующей синхронизации")
                break
            }

            await withTaskGroup(of: (id: UUID, success: Bool).self) { group in
                for task in ready {
                    group.addTask {
                        do {
                            try await self.executeTask(task)
                            return (task.id, true)
                        } catch {
                            return (task.id, false)
                        }
                    }
                }
                for await result in group where !result.success {
                    blockedIDs.insert(result.id)
                }
            }

            remaining.removeAll { task in ready.contains { $0.id == task.id } }
        }
    }

    /// Создаёт таску синхронизации. `entityID` — объект, который таска создаёт/меняет;
    /// `dependsOnEntityIDs` — другие сущности, от которых эта таска зависит (например,
    /// транзакция зависит от обоих счетов, счёт — от своей группы и родителя). Планировщик
    /// (executeDBTasks) сам находит среди ещё не выполненных тасок те, что относятся к этим
    /// сущностям, и не даёт текущей таске выполниться раньше них.
    func createTask<T: Encodable>(
        actionName: ActionName,
        reqModel: T,
        entityID: UUID,
        dependsOnEntityIDs: [UUID] = []
    ) async throws {
        let fieldsJSON = try JSONEncoder().encode(reqModel)

        let relevantIDs = Set(dependsOnEntityIDs + [entityID])
        let pendingTasks = try await repository.getSyncTasks()
        let dependsOnTaskIDs = pendingTasks
            .filter { relevantIDs.contains($0.entityID) }
            .map(\.id)

        try await repository.createTask(SyncTask(
            actionName: actionName,
            tryCount: 0,
            fieldsJSON: fieldsJSON,
            entityID: entityID,
            dependsOnTaskIDs: dependsOnTaskIDs
        ))
    }
    
    private func executeTask(_ task: SyncTask) async throws {
        
        let decoder = JSONDecoder()
        
        do {
            switch task.actionName {
            case .createTransaction:
                let req = try decoder.decode(CreateTransactionReq.self, from: task.fieldsJSON)
                try await apiManager.CreateTransaction(req: req)
                
            case .updateTransaction:
                let req = try decoder.decode(UpdateTransactionReq.self, from: task.fieldsJSON)
                try await apiManager.UpdateTransaction(req: req)

            case .deleteTransaction:
                let req = try decoder.decode(DeleteTransactionReq.self, from: task.fieldsJSON)
                try await apiManager.DeleteTransaction(req: req)
                
            case .createAccount:
                let req = try decoder.decode(CreateAccountReq.self, from: task.fieldsJSON)
                try await apiManager.CreateAccount(req: req)
                
            case .updateAccount:
                let req = try decoder.decode(UpdateAccountReq.self, from: task.fieldsJSON)
                try await apiManager.UpdateAccount(req: req)

            case .deleteAccount:
                let req = try decoder.decode(DeleteAccountReq.self, from: task.fieldsJSON)
                try await apiManager.DeleteAccount(req: req)
                
            case .createTag:
                let req = try decoder.decode(CreateTagReq.self, from: task.fieldsJSON)
                try await apiManager.CreateTag(req: req)
                
            case .updateTag:
                let req = try decoder.decode(UpdateTagReq.self, from: task.fieldsJSON)
                try await apiManager.UpdateTag(req: req)

            case .deleteTag:
                let req = try decoder.decode(DeleteTagReq.self, from: task.fieldsJSON)
                try await apiManager.DeleteTag(req: req)
                
            case .createAccountGroup:
                let req = try decoder.decode(CreateAccountGroupReq.self, from: task.fieldsJSON)
                try await apiManager.CreateAccountGroup(req: req)
                
            case .updateAccountGroup:
                let req = try decoder.decode(UpdateAccountGroupReq.self, from: task.fieldsJSON)
                try await apiManager.UpdateAccountGroup(req: req)
                
            case .deleteAccountGroup:
                let req = try decoder.decode(DeleteAccountGroupReq.self, from: task.fieldsJSON)
                try await apiManager.DeleteAccountGroup(req: req)
                
            case .updateUser:
                let req = try decoder.decode(UpdateUserReq.self, from: task.fieldsJSON)
                try await apiManager.UpdateUser(req: req)

            case .createAccountBudget:
                let req = try decoder.decode(CreateAccountBudgetReq.self, from: task.fieldsJSON)
                try await apiManager.CreateAccountBudget(req: req)
            }
        } catch {
            logger.warning("\(error)")

            // 409 значит, что локальный чекпоинт синхронизации отстал от сервера — подтягиваем
            // его инкрементальным Sync/ConfirmSync. Саму таску это не решает: она остаётся в
            // очереди с увеличенным tryCount и просто переиграется на следующем executeDBTasks
            // (см. incrementalSync ниже) — никакого отдельного UI-сигнала не добавляем.
            if (error as? ErrorModel)?.code == 409 {
                try? await incrementalSync()
            }

            var task = task
            task.tryCount += 1
            task.error = "\(error)"
            do {
                try await repository.updateTask(task)
            } catch {
                logger.warning("\(error)")
            }
            throw error
        }

        try await repository.completeTasks(ids: [task.id])
    }

    /// Лёгкая инкрементальная синхронизация поверх полного Service.sync() (который остаётся
    /// нетронутым как путь для бутстрапа/ручного refresh) — подтягивает чужие изменения по
    /// чекпоинту аудит-лога устройства. Вызывается по таймеру и при получении 409 на мутацию.
    func incrementalSync() async throws {
        guard !incrementalSyncInProgress else { return }
        incrementalSyncInProgress = true
        lastIncrementalSyncStartedAt = Date.now
        defer { incrementalSyncInProgress = false }

        do {
            let res = try await apiManager.Sync(req: SyncReq(sinceID: SyncStateStorage.shared.lastSyncedAuditLogID))
            guard res.hasChanges, let pendingSyncToken = res.pendingSyncToken else {
                lastIncrementalSyncSummary = "Изменений нет"
                lastIncrementalSyncError = nil
                lastIncrementalSyncFinishedAt = Date.now
                return
            }

            let affectedAccountIDs = try await repository.applySyncChanges(res)

            // Сервер присылает изменённый account только если поменялись ЕГО поля — простое
            // появление/удаление транзакции по счёту не бьёт remainder автоматически, поэтому
            // досчитываем баланс задействованных счетов сами, как и при локальных мутациях
            // (см. TransactionService.createTransaction/updateTransaction/deleteTransaction).
            if !affectedAccountIDs.isEmpty {
                try await repository.recalculateBalances(accountIDs: Array(affectedAccountIDs))
            }

            do {
                try await apiManager.ConfirmSync(req: ConfirmSyncReq(pendingSyncToken: pendingSyncToken))
                SyncStateStorage.shared.lastSyncedAuditLogID = res.pendingCheckpoint
                lastIncrementalSyncSummary = incrementalSyncSummary(res)
                lastIncrementalSyncError = nil
            } catch let error as ErrorModel where error.code == 409 || error.code == 400 {
                // Токен устарел — на бэке уже появились более новые изменения поверх этого
                // pending-чекпоинта. Чекпоинт не двигаем, следующий вызов (таймер/следующий 409 на
                // мутации) переспросит Sync заново с прежним sinceID.
                logger.warning("ConfirmSync: устаревший токен, попробуем в следующий раз")
                lastConfirmSyncConflict = Date.now
                lastIncrementalSyncSummary = incrementalSyncSummary(res) + " (не подтверждено — устаревший токен)"
            }
            lastIncrementalSyncFinishedAt = Date.now
        } catch {
            lastIncrementalSyncError = "\(error)"
            lastIncrementalSyncFinishedAt = Date.now
            throw error
        }
    }

    private func incrementalSyncSummary(_ res: SyncRes) -> String {
        var parts: [String] = []
        if !res.changedTransactions.isEmpty { parts.append("\(res.changedTransactions.count) тр.") }
        if !res.deletedTransactionIDs.isEmpty { parts.append("−\(res.deletedTransactionIDs.count) тр.") }
        if !res.changedAccounts.isEmpty { parts.append("\(res.changedAccounts.count) счетов") }
        if !res.deletedAccountIDs.isEmpty { parts.append("−\(res.deletedAccountIDs.count) счетов") }
        if !res.changedAccountGroups.isEmpty { parts.append("\(res.changedAccountGroups.count) групп") }
        if !res.deletedAccountGroupIDs.isEmpty { parts.append("−\(res.deletedAccountGroupIDs.count) групп") }
        if !res.changedTags.isEmpty { parts.append("\(res.changedTags.count) тегов") }
        if !res.deletedTagIDs.isEmpty { parts.append("−\(res.deletedTagIDs.count) тегов") }
        if !res.changedAccountBudgets.isEmpty { parts.append("\(res.changedAccountBudgets.count) бюджетов") }
        if res.changedUser != nil { parts.append("пользователь") }
        if !res.changedCurrencies.isEmpty { parts.append("\(res.changedCurrencies.count) валют") }
        return parts.isEmpty ? "Изменений нет" : parts.joined(separator: ", ")
    }

    func getSyncTasks(
        ids: [UUID]? = nil,
        includeCompleted: Bool = false
    ) async throws -> [SyncTask] {
        return try await repository.getSyncTasks(ids: ids, includeCompleted: includeCompleted)
    }

    func completeTasks(
        ids: [UUID]? = nil
    ) async throws {
        return try await repository.completeTasks(ids: ids)
    }
    
    func getCountTasks() async throws -> UInt32 {
        return try await repository.getCountTasks()
    }
}

enum ActionName: String, Codable {
    case createTransaction, updateTransaction, deleteTransaction
    case createAccount, updateAccount, deleteAccount
    case createTag, updateTag, deleteTag
    case createAccountGroup, updateAccountGroup, deleteAccountGroup
    case updateUser
    case createAccountBudget
}
