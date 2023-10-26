//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

@main
struct MyApp: App {
    
    @State private var modelData = ModelData()
    
    @AppStorage("isDarkMode") var isDarkMode = false
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorText") var errorText: String = ""
    @AppStorage("errorDescription") var errorDescription: String = ""

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
                            }
                    )
                }
        }
    }
}

class Alerter {
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorText") var errorText: String?
    @AppStorage("errorDescription") var errorDescription: String?
    
    func showErrorAlert(error: ErrorModel) {
        isErrorShowing = true
        errorText = error.humanTextError
        errorDescription = error.developerTextError
        print(error.developerTextError)
        print(error.context ?? "")
    }
    
}



