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
        
        taskManager.createTask(
            actionName: .updateUser,
            localObjectID: newUser.id,
            reqModel: UpdateUserReq(
                name: newUser.name != oldUser.name ? newUser.name : nil,
                email: newUser.email != oldUser.email ? newUser.email : nil,
//                password: newUser.password != oldUser.password ? newUser.password : nil,
//                oldPassword: newUser.oldPassword != oldUser.oldPassword ? newUser.oldPassword : nil,
                defaultCurrency: newUser.defaultCurrency.code != oldUser.defaultCurrency.code ? newUser.defaultCurrency.code : nil,
                notificationToken: newUser.notificationToken != oldUser.notificationToken ? newUser.notificationToken : nil
            )
        )
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
