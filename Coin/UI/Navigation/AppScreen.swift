//
//  Navigation.swift
//  Coin
//
//  Created by Илья on 15.11.2023.
//

import SwiftUI

enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
    case home
    case accountCircles
    case budgets
    case transactions
    case profile
    
    var id: AppScreen { self }
}

extension AppScreen {
    @ViewBuilder
    var label: some View {
        switch self {
        case .home: Label("Дом", systemImage: "list.bullet.rectangle.fill")
        case .accountCircles: Label("Счета", systemImage: "2.circle")
        case .budgets: Label("Бюджеты", systemImage: "ruler.fill")
        case .transactions: Label("Транзакции", systemImage: "3.circle")
        case .profile: Label("Профиль", systemImage: "person.fill")
        }
    }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .home: AccountsHomeView()
        case .accountCircles: AccountCirclesView()
        case .budgets: BudgetsList()
        case .transactions: TransactionsView()
        case .profile: Profile()
        }
    }
}
