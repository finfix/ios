//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    
    var body: some View {
        if isLogin {
            AppTabView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AlertManager(handle: {_ in }))
}
