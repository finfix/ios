//
//  PlusNewAccount.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import SwiftUI

enum PlusNewAccountRoute: Hashable {
    case createAccount(AccountType)
}

struct PlusNewAccount: View {
    
    @Environment(PathSharedState.self) var path
    var accountType: AccountType
    
    var body: some View {
        NavigationLink(value: PlusNewAccountRoute.createAccount(accountType)) {
            VStack {
                ZStack {
                    Circle()
                        .stroke(.gray, lineWidth: 2)
                        .foregroundColor(.clear)
                        .frame(width: 30)
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                }
                .foregroundColor(.primary)
            }
            .frame(width: 80, height: 100)
        }
    }
}

#Preview {
    PlusNewAccount(accountType: .regular)
        .environment(AlertManager(handle: {_ in }))
}
