//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import SwiftData
import OSLog
import CoreData

private let logger = Logger(subsystem: "Coin", category: "Main")

@main
struct MyApp: App {
        
    @AppStorage("isDarkMode") var isDarkMode = defaultIsDarkMode
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorTitle") var errorText: String = ""
    @AppStorage("errorDescription") var errorDescription: String = ""
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .alert(isPresented: $isErrorShowing) {
                    Alert(title: 
                            Text(errorText),
                          message:
                            Text(errorDescription),
                          dismissButton:
                            .cancel(Text("OK")) {
                                errorText = ""
                                errorDescription = ""
                            }
                    )
                }
        }
        .modelContainer(container)
    }
}

func showErrorAlert(_ title: String, description: String? = nil) {
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorTitle") var errorText: String?
    @AppStorage("errorDescription") var errorDescription: String?
    
    errorText = title
    errorDescription = description
    isErrorShowing = true
}



