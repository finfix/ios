//
//  TaskManager.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import Foundation
import OSLog
import GRDB

enum ActionName: String, Codable {
    case createTransaction, updateTransaction, deleteTransaction
    case createAccount, updateAccount, deleteAccount
    case createTag, updateTag, deleteTag
    case createAccountGroup, updateAccountGroup, deleteAccountGroup
    case updateUser
    case createAccountBudget
    case createPendingLinkedTransfer, updatePendingLinkedTransfer, deletePendingLinkedTransfer
}
