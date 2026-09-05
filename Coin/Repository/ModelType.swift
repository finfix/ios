//
//  Repository.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB
import OSLog

enum ModelType: String, Codable {
    case account, transaction, tag, icon, user, accountGroup
}
