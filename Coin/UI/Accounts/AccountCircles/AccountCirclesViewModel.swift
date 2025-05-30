//
//  AccountCirclesViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import SwiftUI
import Factory

@Observable
class AccountCirclesViewModel {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accounts: [Account] = []
    var isEditMode: Bool = false
        
    @MainActor
    func load(accountGroup: AccountGroup) async throws {
        self.accounts = Account.groupAccounts(try await service.getAccounts(accountGroups: [accountGroup], visible: true))
    }
    
    var highlitedAccount: Account? = nil
    
    var draggableLocation: CGPoint? = nil
    var draggableAccount: Account? = nil
    @ObservationIgnored var staticLocations: [Account: CGPoint] = [:]
    
    let triggerZone: CGFloat = 50
    
    func initializateStaticLocations(location: CGPoint, for account: Account, in accountGroup: AccountGroup) {
        guard account.accountGroup.id == accountGroup.id else { return }
        self.staticLocations[account] = location
    }
    
    func deleteStaticLocations() {
        self.staticLocations = [Account: CGPoint]()
    }
    
    func updateDraggableLocation(location draggableLocation: CGPoint, for draggableAccount: Account) {
        self.draggableLocation = draggableLocation
        self.draggableAccount = draggableAccount
        var needReset = false
        for (staticAccount, staticLocation) in staticLocations where abs(staticLocation.x - draggableLocation.x) < triggerZone && abs(staticLocation.y - draggableLocation.y) < triggerZone {
            switch (true) {
            case staticAccount == draggableAccount: needReset = true
            case draggableAccount.type == .earnings && staticAccount.type == .regular: highlitedAccount = staticAccount
            case draggableAccount.type == .regular && staticAccount.type == .regular: highlitedAccount = staticAccount
            case draggableAccount.type == .regular && staticAccount.type == .expense: highlitedAccount = staticAccount
            default: needReset = true
            }
        }
        if needReset {
            self.highlitedAccount = nil
        }
    }
    
    func isHighligted(for account: Account) -> Bool {
        self.highlitedAccount == account
    }
}
