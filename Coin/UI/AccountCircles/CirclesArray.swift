//
//  CircleArray.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct CirclesArray: View {
    
    var accounts: [Account]
    
    var accountsType: AccountType
    @State var isOpenCreate = false
    
    var body: some View {
        Group {
            ForEach(accounts.filter { ($0.type == accountsType) && $0.visible }) { account in
                AccountCircleItem(account: account)
            }
            
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
            .navigationDestination(isPresented: $isOpenCreate) {
                CreateAccount(isOpeningFrame: $isOpenCreate, accountType: accountsType)
            }
        }
    }
}

#Preview {
    CirclesArray(accounts: ModelData().accounts, accountsType: .regular)
}
