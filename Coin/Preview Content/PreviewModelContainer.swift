//
//  PreviewModelContainer.swift
//  Coin
//
//  Created by Илья on 14.11.2023.
//

import SwiftUI
import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    do {
        return try ModelContainer (for: Transaction.self, User.self, Account.self, AccountGroup.self, Currency.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    } catch {
        fatalError("Failed to create preview container")
    }
}()
