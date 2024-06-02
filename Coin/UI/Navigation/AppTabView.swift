//
//  AppTabView.swift
//  Coin
//
//  Created by Илья on 15.11.2023.
//

import SwiftUI

@Observable
final class AccountGroupSharedState {
    var selectedAccountGroup = AccountGroup()
}

@Observable
final class PathSharedState {
    var path = NavigationPath()
}

struct AppTabView: View {
        
    func requestPushAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Включили пуши")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    init() {
        requestPushAuthorization()
        UIApplication.shared.registerForRemoteNotifications()
    }
        
    @State var selectedAccountGroup = AccountGroupSharedState()
    
    @State var selectionTab = 1
    
    @State var accountHomeViewPath = PathSharedState()
    @State var accountCirclesPath = PathSharedState()
    @State var transactionTabPath = PathSharedState()
    @State var profilePath = PathSharedState()

    
    var body: some View {
        TabView(selection: $selectionTab) {
            AccountsHomeView()
                .tag(1)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Счета")
                }
                .environment(accountHomeViewPath)
            AccountCirclesView()
                .tag(2)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Счета 2")
                }
                .environment(accountCirclesPath)
            TransactionsTab()
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
                .environment(transactionTabPath)
            Profile()
                .tag(4)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .environment(profilePath)
        }
        .environment(selectedAccountGroup)
    }
}

#Preview {
    AppTabView()
}
