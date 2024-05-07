//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    private let taskManager = TaskManager.shared
    
    var body: some View {
        if isLogin {
            AppTabView()
                .task {
                    Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                        taskManager.executeDBTasks()
                    }
                }
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AlertManager(handle: {_ in }))
}
