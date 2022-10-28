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
                .alert(isPresented: $appSettings.alertErrorShowing) {
                    Alert(title: Text(appSettings.alertErrorMessage), dismissButton: .cancel(Text("OK")))
                }
        }
    }
}

class AppSettings: ObservableObject {
    @Published var isLogin = true
    
    @Published fileprivate var alertErrorShowing = false
    @Published fileprivate var alertErrorMessage = ""
    
    func showErrorAlert(error: ErrorModel) {
        alertErrorShowing = true
        alertErrorMessage = error.humanTextError
        print(error.path)
        print(error.developerTextError)
        print(error.context ?? "")
    }
    
}



