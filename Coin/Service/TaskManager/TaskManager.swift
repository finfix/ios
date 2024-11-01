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
    
    func executeDBTasks() {
        Task {
            do {
                let countTasks = try await repository.getCountTasks()
                guard countTasks > 0 else {
                    return
                }
                logger.log("Количество тасок: \(countTasks)")
                for i in 0..<countTasks {
                    let tasks = try await repository.getSyncTasks(limit: 1)
                    guard !tasks.isEmpty else {
                        logger.error("Количество тасок \(countTasks), но мы не смогли получить из базы данных \(i) таску")
                        return
                    }
                    try await executeTask(tasks[0])
                }
            } catch {
                logger.warning("\(error)")
            }
        }
    }
    
    func createTask<T: FieldExtractable>(
        actionName: ActionName,
        localObjectID: UInt32,
        reqModel: T,
        addictionalMapping: [String: UInt32] = [:]
    ) {
        Task {
            var fields = reqModel.convertToFields()
            for (name, localID) in addictionalMapping {
                fields.append(SyncTaskValue(
                    name: name,
                    value: String(localID)
                ))
            }
            try await repository.createTask(SyncTask(
                localID: localObjectID,
                actionName: actionName,
                tryCount: 0,
                fields: fields,
                enabled: true
            ))
        }
    }
    
    private func executeTask(_ task: SyncTask) async throws {
        
        var fields: [String: String] = [:]
        for field in task.fields {
            fields[field.name] = field.value
        }
        
        do {
            switch task.actionName {
            case .createTransaction:
                let id = try await apiManager.CreateTransaction(req: CreateTransactionReq(fields))
                try await repository.updateServerID(localID: task.localID, modelType: .transaction, serverID: id)
                
            case .updateTransaction:
                try await apiManager.UpdateTransaction(req: UpdateTransactionReq(fields))

            case .deleteTransaction:
                try await apiManager.DeleteTransaction(req: DeleteTransactionReq(fields))
                
            case .createAccount:
                let model = try await apiManager.CreateAccount(req: CreateAccountReq(fields))
                try await repository.updateServerID(localID: task.localID, modelType: .account, serverID: model.id)
                if let localBalancingTransactionID = fields["balancingTransactionID"] {
                    if let serverBalancingTransactionID = model.balancingTransactionID {
                        try await repository.updateServerID(localID: UInt32(localBalancingTransactionID)!, modelType: .transaction, serverID: serverBalancingTransactionID)
                    } else {
                        logger.error("С сервера не пришел идентификатор транзакции балансировки для счета ID: \(fields["id"] ?? "")")
                    }
                }
                if let localBalancingAccountID = fields["balancingAccountID"] {
                    if let serverBalancingAccountID = model.balancingAccountID {
                        try await repository.updateServerID(localID: UInt32(localBalancingAccountID)!, modelType: .account, serverID: serverBalancingAccountID)
                    } else {
                        logger.error("С сервера не пришел идентификатор нового балансировочного счета")
                    }
                }

                
            case .updateAccount:
                let model = try await apiManager.UpdateAccount(req: UpdateAccountReq(fields))
                if let localBalancingTransactionID = fields["balancingTransactionID"] {
                    if let serverBalancingTransactionID = model.balancingTransactionID {
                        try await repository.updateServerID(localID: UInt32(localBalancingTransactionID)!, modelType: .transaction, serverID: serverBalancingTransactionID)
                    } else {
                        logger.error("С сервера не пришел идентификатор транзакции балансировки для счета ID: \(fields["id"] ?? "")")
                    }
                }
                if let localBalancingAccountID = fields["balancingAccountID"] {
                    if let serverBalancingAccountID = model.balancingAccountID {
                        try await repository.updateServerID(localID: UInt32(localBalancingAccountID)!, modelType: .account, serverID: serverBalancingAccountID)
                    } else {
                        logger.error("С сервера не пришел идентификатор нового балансировочного счета")
                    }
                }

            case .deleteAccount:
                try await apiManager.DeleteAccount(req: DeleteAccountReq(fields))
                
            case .createTag:
                let id = try await apiManager.CreateTag(req: CreateTagReq(fields))
                try await repository.updateServerID(localID: task.localID, modelType: .tag, serverID: id)
                
            case .updateTag:
                try await apiManager.UpdateTag(req: UpdateTagReq(fields))

            case .deleteTag:
                try await apiManager.DeleteTag(req: DeleteTagReq(fields))
                
            case .createAccountGroup:
                let model = try await apiManager.CreateAccountGroup(req: CreateAccountGroupReq(fields))
                try await repository.updateServerID(localID: task.localID, modelType: .accountGroup, serverID: model.id)
                
            case .updateAccountGroup:
                try await apiManager.UpdateAccountGroup(req: UpdateAccountGroupReq(fields))
                
            case .deleteAccountGroup:
                try await apiManager.DeleteAccountGroup(req: DeleteAccountGroupReq(fields))
                
            case .updateUser:
                try await apiManager.UpdateUser(req: UpdateUserReq(fields))
            }
        } catch {
            logger.warning("\(error)")
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
        
        try await repository.deleteTasks(ids: [task.id])
    }
    
    func getSyncTasks(
        ids: [UInt32]? = nil
    ) async throws -> [SyncTask] {
        return try await repository.getSyncTasks(ids: ids)
    }
    
    func deleteTasks(
        ids: [UInt32]? = nil
    ) async throws {
        return try await repository.deleteTasks(ids: ids)
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
}

protocol FieldExtractable {
    func convertToFields() -> [SyncTaskValue]
}
