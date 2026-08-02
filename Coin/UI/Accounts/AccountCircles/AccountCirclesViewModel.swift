//
//  AccountCirclesViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesViewModel")

@Observable
class AccountCirclesViewModel {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accounts: [Account] = []
    var currentAccountGroup: AccountGroup? = nil

    @MainActor
    func load(accountGroup: AccountGroup) async throws {
        logger.debug("load: начало для группы '\(accountGroup.name)'")
        self.currentAccountGroup = accountGroup
        // Очищаем счета немедленно, чтобы не было фантомных регистраций в staticLocations
        // пока AccountsTabView пересоздаётся с новой группой (из-за .id(groupID))
        self.accounts = []
        let loaded = try await service.getAccounts(accountGroups: [accountGroup], visible: true)
        guard currentAccountGroup?.id == accountGroup.id else {
            logger.warning("load: отменён для '\(accountGroup.name)' — currentAccountGroup уже '\(self.currentAccountGroup?.name ?? "nil")'")
            return
        }
        deleteStaticLocations()
        self.accounts = Account.groupAccounts(loaded)
        logger.debug("load: завершён для '\(accountGroup.name)', счетов: \(loaded.count)")
    }

    var highlitedAccount: Account? = nil

    var draggableLocation: CGPoint? = nil
    var draggableAccount: Account? = nil
    @ObservationIgnored var staticLocations: [UUID: CGPoint] = [:]

    let triggerZone: CGFloat = 50

    func initializateStaticLocations(location: CGPoint, for account: Account, in accountGroup: AccountGroup) {
        guard accountGroup.id == currentAccountGroup?.id else {
            logger.warning("initializateStaticLocations: отклонён '\(account.name)' группа '\(accountGroup.name)' != current '\(self.currentAccountGroup?.name ?? "nil")'")
            return
        }
        self.staticLocations[account.id] = location
        logger.debug("initializateStaticLocations: зарегистрирован '\(account.name)' total=\(self.staticLocations.count)")
    }

    func deleteStaticLocations() {
        logger.debug("deleteStaticLocations: очищено \(self.staticLocations.count) локаций")
        self.staticLocations = [UUID: CGPoint]()
    }
    
    func updateDraggableLocation(location draggableLocation: CGPoint, for draggableAccount: Account) {
        self.draggableLocation = draggableLocation
        self.draggableAccount = draggableAccount

        // Строим плоский список всех счетов (включая дочерние) для поиска по UUID
        let allAccounts = accounts.flatMap { [$0] + $0.childrenAccounts }

        var needReset = false
        for (accountID, staticLocation) in staticLocations
            where abs(staticLocation.x - draggableLocation.x) < triggerZone
            && abs(staticLocation.y - draggableLocation.y) < triggerZone {
            guard let staticAccount = allAccounts.first(where: { $0.id == accountID }) else { continue }
            switch (true) {
            case staticAccount.id == draggableAccount.id: needReset = true
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
