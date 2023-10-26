//
//  ErrorModel.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation

struct ErrorModel: Decodable {
    var developerTextError: String = ""
    var humanTextError: String = ""
    var statusCode: Int?
    var context: String?
}
