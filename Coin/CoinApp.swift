//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import OSLog
import Factory
import ProtoDefinitions
import SwiftProtobuf
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf

private let logger = Logger(subsystem: "Coin", category: "Main")



extension Container {
    var service: Factory<Service> {
        Factory(self) {
            do {
//                #if DEBUG
//                #endif
                
                // 1. Создаём транспорт с NIO (адрес берётся из UserDefaults, иначе дефолтный)
                let grpcHost = UserDefaults.standard.string(forKey: "grpcHost") ?? defaultGrpcHost
                let grpcPort = UserDefaults.standard.integer(forKey: "grpcPort")
                let transport = try HTTP2ClientTransport.Posix(
                    target: .dns(host: grpcHost, port: grpcPort != 0 ? grpcPort : defaultGrpcPort),
                    transportSecurity: .tls
                )
                
                // ⚠️ transport нужно запустить (в фоне)
                Task.detached {
                    try await transport.connect()
                }
                
                // 2. Создаём GRPCClient с транспортом
                let grpcClient = GRPCClient(transport: transport)
                
                // 3. Создаём клиенты для всех эндпоинтов
                let transactionClient = Transaction_TransactionEndpoint.Client(wrapping: grpcClient)
                let accountClient = Account_AccountEndpoint.Client(wrapping: grpcClient)
                let accountGroupClient = AccountGroup_AccountGroupEndpoint.Client(wrapping: grpcClient)
                let authClient = Auth_AuthEndpoint.Client(wrapping: grpcClient)
                let settingsClient = Settings_SettingsEndpoint.Client(wrapping: grpcClient)
                let tagClient = Tag_TagEndpoint.Client(wrapping: grpcClient)
                let userClient = User_UserEndpoint.Client(wrapping: grpcClient)
                let auditLogClient = AuditLog_AuditLogEndpoint.Client(wrapping: grpcClient)
                let accountBudgetClient = AccountBudget_AccountBudgetEndpoint.Client(wrapping: grpcClient)
                let syncClient = Sync_SyncEndpoint.Client(wrapping: grpcClient)
                let pendingLinkedTransferClient = PendingLinkedTransfer_PendingLinkedTransferEndpoint.Client(wrapping: grpcClient)

                // 4. Создаём менеджеры с gRPC клиентами
                let authManager = AuthManager(authClient: authClient)
                let apiManager = APIManager(
                    authManager: authManager,
                    authClient: authClient,
                    transactionClient: transactionClient,
                    accountClient: accountClient,
                    accountGroupClient: accountGroupClient,
                    userClient: userClient,
                    tagClient: tagClient,
                    settingsClient: settingsClient,
                    auditLogClient: auditLogClient,
                    accountBudgetClient: accountBudgetClient,
                    syncClient: syncClient,
                    pendingLinkedTransferClient: pendingLinkedTransferClient
                )
                
                let sqlite = try SQLite()
                let repository = Repository(sqlite: sqlite)
                
                let taskManager = TaskManager(repository: repository, apiManager: apiManager)
                return Service(repository: repository, apiManager: apiManager, taskManager: taskManager, authManager: authManager)
            } catch {
                fatalError("Произошла ошибка при инициализации зависимости Service \(error)")
            }
        }.singleton
    }
    
    var alertManager: Factory<AlertManager> {
        return Factory(self) { return AlertManager() }.singleton
    }
}


