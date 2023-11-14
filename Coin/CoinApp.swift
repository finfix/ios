//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import SwiftData

@main
struct MyApp: App {
        
    @AppStorage("isDarkMode") var isDarkMode = defaultIsDarkMode
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorTitle") var errorText: String = ""
    @AppStorage("errorDescription") var errorDescription: String = ""
    
    var container: ModelContainer

    init() {
        do {
            let schema = Schema([Currency.self, User.self, Transaction.self, Account.self, AccountGroup.self])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
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
    
    isErrorShowing = true
    errorText = title
    errorDescription = description
    debugLog(title)
    if let description {
        debugLog(description)
    }
}



