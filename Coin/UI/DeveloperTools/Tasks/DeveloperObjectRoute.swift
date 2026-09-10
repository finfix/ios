//
//  TaskDetailsViewModel.swift
//  Coin
//
//  Created by Илья on 10.05.2024.
//

import Foundation
import Factory
import GRDB

/// Экран, на который нужно перейти для конкретного объекта, связанного с таской синхронизации.
enum DeveloperObjectRoute: Hashable {
    case account(Account)
    case transaction(Transaction)
    case tag(Tag)
    case accountGroup(AccountGroup)
}
