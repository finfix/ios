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
    
    func executeDBTasks() async throws {
        
        if syncInProgress {
            logger.warning("Синхронизация в процессе, ждем ответа от сервера")
            return
        }
        
        syncInProgress = true
        defer { syncInProgress = false }
        
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
    }
    
    func createTask<T: Encodable>(
        actionName: ActionName,
        reqModel: T
    ) {
        Task {
            
            let fieldsJSON = try JSONEncoder().encode(reqModel)
            
            try await repository.createTask(SyncTask(
                actionName: actionName,
                tryCount: 0,
                fieldsJSON: fieldsJSON,
                enabled: true
            ))
        }
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
        ids: [UUID]? = nil
    ) async throws -> [SyncTask] {
        return try await repository.getSyncTasks(ids: ids)
    }
    
    func deleteTasks(
        ids: [UUID]? = nil
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
