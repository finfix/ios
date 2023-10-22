//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

@main
struct MyApp: App {
    
    @State private var appSettings = AppSettings()
    @State private var modelData = ModelData()
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environment(appSettings)
                .environment(modelData)
                .alert(isPresented: $appSettings.alertErrorShowing) {
                    Alert(title: Text(appSettings.alertErrorMessage), message: Text(appSettings.alertErrorDetails), dismissButton: .cancel(Text("OK")))
                }
        }
    }
}

@Observable
class AppSettings {
    var isLogin = true
    
    fileprivate var alertErrorShowing = false
    fileprivate var alertErrorMessage = ""
    fileprivate var alertErrorDetails = ""
    
    func showErrorAlert(error: ErrorModel) {
        alertErrorShowing = true
        alertErrorMessage = error.humanTextError
        alertErrorDetails = error.developerTextError
        print(error.developerTextError)
        print(error.context ?? "")
    }
    
}



