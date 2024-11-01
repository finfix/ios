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
    @AppStorage("isDeveloperMode") var isDevMode = false
    
    var body: some View {
        TabView(selection: $selectionTab) {
            AccountHomeTab()
                .tag(1)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Счета")
                }
            AccountCirclesTab()
                .tag(2)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Счета 2")
                }
            TransactionsTab()
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
            ProfileTab()
                .tag(4)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
#if DEV
            if isDevMode {
                DeveloperToolsTab()
                    .tag(5)
                    .tabItem {
                        Image(systemName: "hammer.fill")
                        Text("Разработчик")
                    }
            }
#endif
        }
        .environment(selectedAccountGroup)
    }
}

#Preview {
    AppTabView()
}
