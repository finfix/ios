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
    
    @State private var modelData = ModelData()
    
    @AppStorage("isDarkMode") var isDarkMode = false
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorText") var errorText: String = ""
    @AppStorage("errorDescription") var errorDescription: String = ""
    
    var container: ModelContainer

    init() {
        do {
            let storeURL = URL.documentsDirectory.appending(path: "database.sqlite")
            let schema = Schema([Currency.self, User.self])
            let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .private("coin"))
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environment(modelData)
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

func showErrorAlert(error: ErrorModel) {
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorText") var errorText: String?
    @AppStorage("errorDescription") var errorDescription: String?
    
    isErrorShowing = true
    errorText = error.humanTextError
    errorDescription = error.developerTextError
    debugLog(error.developerTextError)
    debugLog(error.context ?? "")
}



