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
