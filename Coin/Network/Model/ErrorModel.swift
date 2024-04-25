//
//  ErrorModel.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation

struct ErrorModel: LocalizedError, Decodable {
    var developerTextError: String = ""
    var humanTextError: String
    var statusCode: Int?
//    var parameters: [String: String]?
    
    var errorDescription: String? {
        var description = self.humanTextError
        #if DEBUG
        description += "\n\n" + self.developerTextError
        #endif
        return description
    }
}
