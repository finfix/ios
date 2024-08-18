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
        password: String
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
        try await sync()
    }
    
    func register(
        login: String,
        password: String,
        name: String
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
        try await sync()
    }
}
