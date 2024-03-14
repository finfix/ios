//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    @State private var selection: AppScreen? = .home
    
    var body: some View {
        if isLogin {
            AppTabView(selection: $selection)
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
