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
    var path: [String]?
    var userInfo: UserInfo?
    var systemInfo: SystemInfo?
    var parameters: [String: String]?
    
    var errorDescription: String? {
        var description = self.humanText
#if DEV
        if self.error != "" {
            description += "\n\n" + self.error
        }
#endif
        return description
    }
    
    struct UserInfo: Decodable {
        let userID: UInt32?
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
