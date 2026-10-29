//
//  UserService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation

extension Service {
    
    // MARK: Read
    func getUsers() async throws -> [User] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await repository.getCurrencies()))
        return User.convertFromDBModel(try await repository.getUsers(), currenciesMap: currenciesMap)
    }
    
    // MARK: Update
    func updateUser(newUser: User, oldUser: User) async throws {

        try await repository.updateUser(newUser)
        
        try await taskManager.createTask(
            actionName: .updateUser,
            reqModel: UpdateUserReq(
                name: newUser.name != oldUser.name ? newUser.name : nil,
                email: newUser.email != oldUser.email ? newUser.email : nil,
                defaultCurrency: newUser.defaultCurrency.code != oldUser.defaultCurrency.code ? newUser.defaultCurrency.code : nil,
                notificationToken: newUser.notificationToken != oldUser.notificationToken ? newUser.notificationToken : nil
            ),
            entityID: newUser.id
        )
    }
    
    /// Смена пароля идёт напрямую на сервер, минуя очередь фоновых задач — нужен ответ сервера (например, неверный старый пароль)
    func changePassword(oldPassword: String, newPassword: String) async throws {
        try await apiManager.UpdateUser(req: UpdateUserReq(
            password: newPassword,
            oldPassword: oldPassword
        ))
    }
    
    // MARK: Other
    func registerNotifications(token: String) async throws {
        // Получаем пользователя
        let users = try await getUsers()
        if let oldUser = users.first {
            
            // Если токен пользователя из бд отличается от пришедшего
            if token == oldUser.notificationToken ?? "" {
                
                var newUser = oldUser
                
                newUser.notificationToken = token
                
                // Обновляем пользователя
                try await updateUser(newUser: newUser, oldUser: oldUser)
            }
        }
    }
}
