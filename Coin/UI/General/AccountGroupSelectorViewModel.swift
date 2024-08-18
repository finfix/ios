//
//  AccountGroupSelectorViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Factory
import SwiftUI

@Observable
class AccountGroupSelectorViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accountGroups: [AccountGroup] = []
    
    func load() async throws {
        accountGroups = try await service.getAccountGroups()
    }
}
