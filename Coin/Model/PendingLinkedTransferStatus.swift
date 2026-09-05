//
//  PendingLinkedTransfer.swift
//  Coin
//

import Foundation

enum PendingLinkedTransferStatus: String, Codable, CaseIterable {
    case pending, completed, ignored
}
