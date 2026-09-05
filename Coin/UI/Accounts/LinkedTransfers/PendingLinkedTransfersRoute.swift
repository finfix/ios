//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

enum PendingLinkedTransfersRoute: Hashable {
    case list
    case completeLinkedTransfer(PendingLinkedTransfer)
}
