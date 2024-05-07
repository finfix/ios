//
//  ErrorModel.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI

struct ErrorModel: LocalizedError, Decodable {
    var humanTextError: String
    var developerTextError: String = ""
//    var parameters: [String: String]?
    
    var errorDescription: String? {
        var description = self.humanTextError
        #if DEBUG
        if self.developerTextError != "" {
            description += "\n\n" + self.developerTextError
        }
        #endif
        return description
    }
}
