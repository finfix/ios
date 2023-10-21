//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Profile: View {
    
    @Environment(AppSettings.self) var appSettings
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        VStack(spacing: 10) {
            Button {
                appSettings.isLogin = false
            } label: {
                Text("Выйти")
            }
            Button {
                modelData.sync()
            } label: {
                Text("Синхронизировать")
            }
        }
    }
}

#Preview {
    Profile()
}
