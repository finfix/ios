//
//  ErrorModel.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI

struct ErrorModel: LocalizedError, Decodable {
    var humanText: String
    var error: String = ""
    /// Категория ошибки, пришедшая от сервера (error.Error.category в контрактах) — заменяет
    /// прежний числовой HTTP-код. Именно на неё завязаны действия после ответа (logout,
    /// need sync), а не на конкретные коды/сообщения.
    var category: ErrorCategory = .unspecified
    var path: [String]?
    var userInfo: UserInfo?
    var systemInfo: SystemInfo?
    var parameters: [String: String]?

    var errorDescription: String? { humanText }

    /// Зеркалит error.ErrorCategory из контрактов (proto/enums/errorCategory.proto).
    enum ErrorCategory: String, Decodable {
        case unspecified
        case internalError
        case needToLogout
        case needToSync
        case other
        case needToRefreshToken
    }

    struct UserInfo: Decodable {
        let userID: UUID?
        let taskID: String?
        let deviceID: String?
    }
    
    struct SystemInfo: Decodable {
        let hostname: String?
        let version: String?
        let build: String?
        let env: String?
    }
}
