//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

@main
struct CoinApp: App {
    
    var trAPI = TransactionAPI()
    var acAPI = AccountAPI()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(trAPI)
                .environmentObject(acAPI)
        }
    }
}
