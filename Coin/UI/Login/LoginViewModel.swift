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
    
    enum Mode {
        case login, register
    }
    
    func auth() async throws {
        shouldDisableUI = true
        defer { shouldDisableUI = false }
        shouldShowProgress = true
        defer { shouldShowProgress = false }
        
        switch mode {
        case .login:
            try await service.auth(
                login: login,
                password: password
            )
        case .register:
            try await service.register(
                login: login,
                password: password,
                name: name
            )
        }
    }
}
