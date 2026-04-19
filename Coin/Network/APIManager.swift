//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import SwiftUI
import OSLog
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

private let logger = Logger(subsystem: "Coin", category: "gRPC")

class APIManager {
    
    init(
        networkManager: NetworkManager,
        authClient: Auth_AuthEndpoint.Client<HTTP2ClientTransport.Posix>,
        transactionClient: Transaction_TransactionEndpoint.Client<HTTP2ClientTransport.Posix>,
        accountClient: Account_AccountEndpoint.Client<HTTP2ClientTransport.Posix>,
        accountGroupClient: AccountGroup_AccountGroupEndpoint.Client<HTTP2ClientTransport.Posix>,
        userClient: User_UserEndpoint.Client<HTTP2ClientTransport.Posix>,
        tagClient: Tag_TagEndpoint.Client<HTTP2ClientTransport.Posix>,
        settingsClient: Settings_SettingsEndpoint.Client<HTTP2ClientTransport.Posix>
    ) {
        self.networkManager = networkManager
        self.authClient = authClient
        self.transactionClient = transactionClient
        self.accountClient = accountClient
        self.accountGroupClient = accountGroupClient
        self.userClient = userClient
        self.tagClient = tagClient
        self.settingsClient = settingsClient
    }
    
    let networkManager: NetworkManager
    var authClient: Auth_AuthEndpoint.Client<HTTP2ClientTransport.Posix>
    var transactionClient: Transaction_TransactionEndpoint.Client<HTTP2ClientTransport.Posix>
    var accountClient: Account_AccountEndpoint.Client<HTTP2ClientTransport.Posix>
    var accountGroupClient: AccountGroup_AccountGroupEndpoint.Client<HTTP2ClientTransport.Posix>
    var userClient: User_UserEndpoint.Client<HTTP2ClientTransport.Posix>
    var tagClient: Tag_TagEndpoint.Client<HTTP2ClientTransport.Posix>
    var settingsClient: Settings_SettingsEndpoint.Client<HTTP2ClientTransport.Posix>
    
    // MARK: - Переподключение gRPC
    
    func reconnect(host: String, port: Int) throws {
        logger.info("Переподключение gRPC → \(host, privacy: .public):\(port, privacy: .public)")
        
        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: host, port: port),
            transportSecurity: .plaintext
        )
        Task.detached { try await transport.connect() }
        
        let grpcClient = GRPCClient(transport: transport)
        
        authClient = Auth_AuthEndpoint.Client(wrapping: grpcClient)
        transactionClient = Transaction_TransactionEndpoint.Client(wrapping: grpcClient)
        accountClient = Account_AccountEndpoint.Client(wrapping: grpcClient)
        accountGroupClient = AccountGroup_AccountGroupEndpoint.Client(wrapping: grpcClient)
        userClient = User_UserEndpoint.Client(wrapping: grpcClient)
        tagClient = Tag_TagEndpoint.Client(wrapping: grpcClient)
        settingsClient = Settings_SettingsEndpoint.Client(wrapping: grpcClient)
        
        // Обновляем authClient в AuthManager (используется для refresh токенов)
        networkManager.authManager.reconnect(authClient: authClient)
        
        logger.info("gRPC переподключён")
    }
    
    // MARK: - Логирование gRPC
    
    func grpcCall<Req: SwiftProtobuf.Message, Res: SwiftProtobuf.Message>(
        _ method: String,
        request: Req,
        perform: (Req) async throws -> Res
    ) async throws -> Res {
        logger.debug("→ \(method, privacy: .public)\n\(request.textFormatString(), privacy: .public)")
        do {
            let response = try await perform(request)
            logger.debug("← \(method, privacy: .public)\n\(response.textFormatString(), privacy: .public)")
            return response
        } catch {
            logger.error("✗ \(method, privacy: .public): \(String(describing: error), privacy: .public)")
            throw error
        }
    }
}
