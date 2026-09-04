//
//  DraggedAccount.swift
//  Coin
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    static let coinAccount = UTType(exportedAs: "com.coin.account")
}

/// Только id — сам Account через Transferable не гоняем, полный объект достаётся из
/// AccountCirclesViewModel.accounts в момент дропа (drag-and-drop чисто внутри приложения).
struct DraggedAccount: Codable, Transferable {
    let accountID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .coinAccount)
    }
}
