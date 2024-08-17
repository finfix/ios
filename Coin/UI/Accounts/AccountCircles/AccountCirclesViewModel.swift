//
//  AccountCirclesViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import SwiftUI

class AccountCirclesViewModel: ObservableObject {
    private let service = Service.shared
    
    @Published var accounts: [Account] = []
        
    func load() async throws {
        accounts = try await service.getAccounts(visible: true)
    }
    
    @Published var highlitedAccount: Account? = nil
    
    @Published var draggableLocation: CGPoint? = nil
    @Published var draggableAccount: Account? = nil
    var staticLocations: [Account: CGPoint] = [:]
    
    let triggerZone: CGFloat = 50
    
    func initializateStaticLocations(location: CGPoint, for account: Account) {
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
