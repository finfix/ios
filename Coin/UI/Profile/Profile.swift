//
//  Profile.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Profile: View {
    
    @Environment(AppSettings.self) var appSettings
    
    var body: some View {
        Button {
            appSettings.isLogin = false
        } label: {
            Text("Выйти")
        }

    }
}

#Preview {
    Profile()
}
