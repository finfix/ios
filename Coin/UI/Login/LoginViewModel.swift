//
//  LoginViewModel.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import SwiftUI
import Factory

@Observable
class LoginViewModel {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    
    init() {}
    
    var mode: Mode = .login
    var login = ""
    var password = ""
    var name = ""
    var isShowPassword = false
    var shouldDisableUI = false
    var shouldShowProgress = false
    /// Доля выполненного sync() после успешной авторизации (0...1) — см. Service.sync(progress:).
    var syncProgress: Double = 0
    
    enum Mode {
        case login, register
    }
    
    func auth() async throws {
        shouldDisableUI = true
        defer { shouldDisableUI = false }
        shouldShowProgress = true
        syncProgress = 0
        defer { shouldShowProgress = false }

        // sync() крутится в фоновом Task, колбэк дёргается не на MainActor — сама доля
        // считается синхронно на стороне Service, поэтому дешёвое обновление @Observable-поля
        // достаточно просто форкнуть на MainActor, без доп. синхронизации.
        let onProgress: (Double) -> Void = { [weak self] fraction in
            Task { @MainActor in self?.syncProgress = fraction }
        }

        switch mode {
        case .login:
            try await service.auth(
                login: login,
                password: password,
                syncProgress: onProgress
            )
        case .register:
            try await service.register(
                login: login,
                password: password,
                name: name,
                syncProgress: onProgress
            )
        }
    }
}
