//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

enum DraggableAccountRoute: Hashable {
case createTransaction(TransactionType, Account, Account)
case completeLinkedTransfer(TransactionType, Account, Account, PendingLinkedTransfer, Decimal, Date)
}
