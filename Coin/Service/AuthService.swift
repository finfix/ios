//
//  AuthService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import SwiftUI

extension Service {
    
    func auth(
        login: String,
        password: String,
        syncProgress: ((Double) -> Void)? = nil
    ) async throws {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            throw ErrorModel(humanText: "Не смогли получить Bundle Identifier приложения")
        }
        let response = try await apiManager.Auth(req: AuthReq(
            email: login,
            password: password,
            application: getApplicationInformation(),
            device: getDeviceInformation()
        ))
        authManager.login(accessToken: response.token.accessToken, refreshToken: response.token.refreshToken)
        try await sync(progress: syncProgress)
    }
    
    /// Только логин + сохранение свежей пары токенов, БЕЗ последующего sync() — для отладки
    /// (Developer Tools), когда нужна валидная пара токенов сама по себе, а тянуть все данные
    /// заново не нужно и может быть нежелательно (например, чтобы не перетереть локально
    /// накопленное расхождение, которое как раз отлаживается).
    func authWithoutSync(
        login: String,
        password: String
    ) async throws {
        let response = try await apiManager.Auth(req: AuthReq(
            email: login,
            password: password,
            application: getApplicationInformation(),
            device: getDeviceInformation()
        ))
        authManager.login(accessToken: response.token.accessToken, refreshToken: response.token.refreshToken)
    }

    func forceRefreshTokens() async throws {
        try await authManager.forceRefreshTokens()
    }

    func register(
        login: String,
        password: String,
        name: String,
        syncProgress: ((Double) -> Void)? = nil
    ) async throws {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            throw ErrorModel(humanText: "Не смогли получить Bundle Identifier приложения")
        }
        let response = try await apiManager.Register(req: RegisterReq(
            email: login,
            password: password,
            name: name,
            application: getApplicationInformation(),
            device: getDeviceInformation()
        ))
        authManager.login(accessToken: response.token.accessToken, refreshToken: response.token.refreshToken)
        try await sync(progress: syncProgress)
    }
}
