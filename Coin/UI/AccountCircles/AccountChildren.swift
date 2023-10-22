//
//  AccountChildren.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import SwiftUI

struct AccountChildren: View {
    
    var children: [Account]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(children) { childAccount in
                    AccountCircleItem(account: childAccount)
                }
            }
        }
    }
}

#Preview {
    AccountChildren(children: ModelData().accounts)
        .environment(ModelData())
}
