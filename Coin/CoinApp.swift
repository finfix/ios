//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "Main")

@main
struct MyApp: App {
        
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
                            .cancel(Text("OK"))
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
}

@Observable
class AlertManager {
    let handle: (AlertModel) -> Void
    
    func callAsFunction(_ error: Error) {
        logger.error("\(error)")
        handle(AlertModel(title: "Произошла ошибка", message: error.localizedDescription))
    }
    
    init(handle: @escaping (AlertModel) -> Void) {
        self.handle = handle
    }
}
