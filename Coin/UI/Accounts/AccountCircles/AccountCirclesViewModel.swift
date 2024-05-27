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
    
    var path = NavigationPath()
    
    @Published var highlitedAccount: Account? = nil
    
    @Published var draggableLocation: CGPoint? = nil
    @Published var draggableAccount: Account? = nil
    var staticLocations: [Account: CGPoint] = [:]
    
    let triggerZone: CGFloat = 50
    
    func initializateStaticLocations(location: CGPoint, for account: Account) {
        self.staticLocations[account] = location
    }
    
    func removeChildrenPositions(account: Account) {
        for parentAccount in accounts {
            for childAccount in parentAccount.childrenAccounts {
                staticLocations.removeValue(forKey: account)
            }
        }
    }
    
    func updateDraggableLocation(location draggableLocation: CGPoint, for draggableAccount: Account) {
        self.draggableLocation = draggableLocation
        self.draggableAccount = draggableAccount
        var needReset = false
        for (staticAccount, staticLocation) in staticLocations where abs(staticLocation.x - draggableLocation.x) < triggerZone && abs(staticLocation.y - draggableLocation.y) < triggerZone {
            switch (true) {
            case staticAccount == draggableAccount: needReset = true
            case staticAccount.isParent: needReset = true
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
        
    func confirmDraggableDrop(for draggableAccount: Account) {
        if let staticAccount = highlitedAccount {
            var transactionType: TransactionType? = nil
            switch (true) {
            case draggableAccount == staticAccount: break
            case staticAccount.isParent: break
            case draggableAccount.type == .earnings && staticAccount.type == .regular: transactionType = .income
            case draggableAccount.type == .regular && staticAccount.type == .regular: transactionType = .transfer
            case draggableAccount.type == .regular && staticAccount.type == .expense: transactionType = .consumption
            default: break
            }
            if let transactionType {
                self.path.append(DraggableAccountRoute.createTransaction(transactionType, draggableAccount, staticAccount))
            }
        }
        self.highlitedAccount = nil
        withAnimation {
            self.draggableLocation = nil
            self.draggableAccount = nil
        }
    }
    
    
    func isHighligted(for account: Account) -> Bool {
        self.highlitedAccount == account
    }
    
}
