//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "Main")

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        Service.shared.registerNotifications(token: token)
    };

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
       print(error.localizedDescription)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}

@main
struct MyApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
        
    @AppStorage("isDarkMode") var isDarkMode = defaultIsDarkMode
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorTitle") var errorText: String = ""
    @AppStorage("errorDescription") var errorDescription: String = ""
    
    @State var alert: AlertModel?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .alert(item: $alert) { alert in
                    Alert(title:
                            Text(alert.title),
                          message:
                            Text(alert.message),
                          dismissButton:
                            .cancel(
                                Text(alert.buttonText),
                                action: {
                                    alert.callback()
                                }
                            )
                    )
                }
                .environment(AlertManager(handle: {
                    alertModel in self.alert = alertModel
                }))
        }
    }
}

struct AlertModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
    let callback: () -> Void
}

@Observable
class AlertManager {
    let handle: (AlertModel) -> Void
    
    func callAsFunction(
        _ error: Error,
        title: String = "Произошла ошибка",
        buttonText: String = "OK",
        callback: @escaping () -> Void = {},
        file: String = #file,
        line: Int = #line
    ) {
        logger.error("\(file):\(line)\n\(error)")
        handle(AlertModel(title: title, message: error.localizedDescription, buttonText: buttonText, callback: callback))
    }
    
    func callAsFunction(
        title: String,
        message: String,
        buttonText: String = "OK",
        callback: @escaping () -> Void = {},
        file: String = #file,
        line: Int = #line
    ) {
        logger.error("\(file):\(line)\n\(title)\n\(message)")
        handle(AlertModel(title: title, message: message, buttonText: buttonText, callback: callback))
    }
    
    init(handle: @escaping (AlertModel) -> Void) {
        self.handle = handle
    }
}
