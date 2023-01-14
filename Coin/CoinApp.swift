//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

@main
struct MyApp: App {
    
    @StateObject var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                // .environmentObject(UserData())
                .alert(isPresented: $appSettings.alertErrorShowing) {
                    Alert(title: Text(appSettings.alertErrorMessage), message: Text(appSettings.alertErrorDetails), dismissButton: .cancel(Text("OK")))
                }
        }
    }
}

class AppSettings: ObservableObject {
    @Published var isLogin = true
    
    @Published fileprivate var alertErrorShowing = false
    @Published fileprivate var alertErrorMessage = ""
    @Published fileprivate var alertErrorDetails = ""
    
    func showErrorAlert(error: ErrorModel) {
        alertErrorShowing = true
        alertErrorMessage = error.humanTextError
        alertErrorDetails = error.developerTextError
        print(error.developerTextError)
        print(error.context ?? "")
    }
    
}



