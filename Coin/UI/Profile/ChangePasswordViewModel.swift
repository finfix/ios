//
//  ChangePasswordViewModel.swift
//  Coin
//
//  Created by Илья on 29.10.2026.
//

import Foundation
import Factory

@Observable
class ChangePasswordViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var oldPassword = ""
    var newPassword = ""
    var repeatPassword = ""
    
    /// Все поля заполнены и новый пароль совпадает с повтором
    var isValid: Bool {
        !oldPassword.isEmpty && !newPassword.isEmpty && newPassword == repeatPassword
    }
    
    func changePassword() async throws {
        try await service.changePassword(oldPassword: oldPassword, newPassword: newPassword)
    }
}
