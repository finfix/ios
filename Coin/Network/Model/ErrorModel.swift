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
    /// HTTP-код ошибки, пришедший от сервера (error.Error.code в контрактах) — например 409,
    /// если мутация отклонена из-за отставания локального чекпоинта синхронизации.
    var code: Int32 = 0
    var path: [String]?
    var userInfo: UserInfo?
    var systemInfo: SystemInfo?
    var parameters: [String: String]?
    
    var errorDescription: String? { humanText }
    
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
