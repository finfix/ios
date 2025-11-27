//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import SwiftUI
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2

class APIManager {
    
    @AppStorage("apiBasePath") var apiBasePath: String = defaultApiBasePath
        
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
    let authClient: Auth_AuthEndpoint.Client<HTTP2ClientTransport.Posix>
    let transactionClient: Transaction_TransactionEndpoint.Client<HTTP2ClientTransport.Posix>
    let accountClient: Account_AccountEndpoint.Client<HTTP2ClientTransport.Posix>
    let accountGroupClient: AccountGroup_AccountGroupEndpoint.Client<HTTP2ClientTransport.Posix>
    let userClient: User_UserEndpoint.Client<HTTP2ClientTransport.Posix>
    let tagClient: Tag_TagEndpoint.Client<HTTP2ClientTransport.Posix>
    let settingsClient: Settings_SettingsEndpoint.Client<HTTP2ClientTransport.Posix>
}
