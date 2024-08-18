//
//  TokenManager.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "API")

class AuthManager {
    
    static let shared = makeShared()
    
    static func makeShared() -> AuthManager {
        AuthManager()
    }
    
    @AppStorage("refreshToken") private var refreshToken: String?
    @AppStorage("apiBasePath") private var apiBasePath: String = ""
    @AppStorage("accessToken") private var accessToken: String?
    @AppStorage("isLogin") private var isLogin: Bool = false
    
    func getAccessToken() async throws -> String {
        
        // Проверяем наличие access токена
        guard var accessToken else {
            logout()
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

        do {
            
            guard let refreshToken else { throw ErrorModel(humanText: "Refresh токен не заполнен")}
            
            let data = try await NetworkManager.shared.request(
                url: NetworkManager.shared.apiBasePath + "/auth/refreshTokens",
                method: .post,
                headers: [
                    "Authorization": accessToken ?? "",
                    "DeviceID": UIDevice.current.identifierForVendor!.uuidString
                ],
                withAuthorization: false,
                body: RefreshTokensReq(
                    token: refreshToken,
                    application: try getApplicationInformation(),
                    device: getDeviceInformation()
                )
            )
            let token = try NetworkManager.shared.decode(data, model: Token.self)
            
            self.accessToken = token.accessToken
            self.refreshToken = token.refreshToken
            return token.accessToken
        } catch {
            throw error
        }
    }
    
    public func logout() {
        isLogin = false
        accessToken = nil
        refreshToken = nil
    }
    
    public func login(
        accessToken: String,
        refreshToken: String
    ) {
        isLogin = true
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
