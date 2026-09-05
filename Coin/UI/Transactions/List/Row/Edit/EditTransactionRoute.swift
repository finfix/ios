//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import OSLog

enum EditTransactionRoute: Hashable {
    case tagsList
    case auditLogHistory(entityID: String, accountGroupID: UUID)
}
