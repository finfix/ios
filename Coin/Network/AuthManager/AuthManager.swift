//
//  TokenManager.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import SwiftUI
import OSLog
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import DeviceKit


private let logger = Logger(subsystem: "Coin", category: "API")

class AuthManager {
    
    private let authClient: Auth_AuthEndpoint.Client<HTTP2ClientTransport.Posix>
    
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("accessToken") private var accessToken: String?
    
    init(authClient: Auth_AuthEndpoint.Client<HTTP2ClientTransport.Posix>) {
        self.authClient = authClient
    }
    
    func getAccessToken() async throws -> String {
        
        // Проверяем наличие access токена
        guard var accessToken else {
            throw ErrorModel(humanText: "Пользователь не авторизован")
        }
         
        // Проверяем токен
        do {
            try checkJWT(accessToken)
            
        } catch JWTError.tokenExpired(_) { // Если токен протух
            do {
                accessToken = try await refreshAccessToken() // Пытаемся получить новый токен
                
            } catch { // Если не получилось
                
                // Выкидываем пользователя
                logout()
                throw error
            }
            
        } catch { // Если другая ошибка
            
            // Выкидываем пользователя
            logout()
            throw error
        }
        
        return accessToken
    }

    private func refreshAccessToken() async throws -> String {
        
        guard let refreshToken else {
            throw ErrorModel(humanText: "Refresh токен не заполнен")
        }
        
        // Формируем protobuf запрос
        let appInfo = try getApplicationInformation()
        let deviceInfo = getDeviceInformation()
        
        let request = Auth_RefreshTokensRequest.with {
            $0.token = refreshToken
            $0.application = Auth_ApplicationInformation.with {
                $0.bundleID = appInfo.bundleID
                $0.version = appInfo.version
                $0.build = appInfo.build
            }
            $0.device = Auth_DeviceInformation.with {
                $0.nameOs = .ios
                $0.versionOs = deviceInfo.versionOS
                $0.deviceName = deviceInfo.deviceName
                $0.modelName = deviceInfo.modelName
                $0.ipAddress = ""
            }
        }
        
        // Делаем gRPC вызов
        let response = try await authClient.refreshTokens(
            request
        )
        
        // Обрабатываем ответ
        if response.hasError {
            throw ErrorModel(humanText: response.error.message)
        }
                
        // Сохраняем токены
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        
        return response.accessToken
    }
    
    public func logout() {
        accessToken = nil
        refreshToken = nil
    }
    
    public func login(
        accessToken: String,
        refreshToken: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
