//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import GRDBQuery
import OSLog

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
                .environment(\.appDatabase, .shared)
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

private struct AppDatabaseKey: EnvironmentKey {
    static var defaultValue: AppDatabase { .empty() }
}

extension EnvironmentValues {
    var appDatabase: AppDatabase {
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

extension Query where Request.DatabaseContext == AppDatabase {
    init(_ request: Request) {
        self.init(request, in: \.appDatabase)
    }
}
