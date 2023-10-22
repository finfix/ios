//
//  PlusNewAccount.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import SwiftUI

struct PlusNewAccount: View {
    
    @State var isOpenCreate = false
    var accountType: AccountType
    
    var body: some View {
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
            .onTapGesture {
                isOpenCreate = true
            }
        }
        .frame(width: 80, height: 100)
        .navigationDestination(isPresented: $isOpenCreate) {
            CreateAccount(isOpeningFrame: $isOpenCreate, accountType: accountType)
        }
    }
}

#Preview {
    PlusNewAccount(accountType: .regular)
}
