//
//  HeaderListAccountType.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountTypeDetailsView: View {
    
    @State var header: String
    @State var showingList = false
    @Binding var accounts: [Account]
    
    var body: some View {
        VStack {
            // Заголовок
            HStack {
                Image(systemName: "chevron.right")
                Text(header)
                Spacer()
                Text("29 323Р")
            }
            .onTapGesture(perform: {
                showingList.toggle()
            })
            .padding()
            if showingList {
                ForEach(accounts, id: \.id) { account in
                    HStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.gray)
                        Text(account.name)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "%.2f", account.remainder))
                    }
                    .padding()
                    .frame(width: 340, height: 60)
                    .background(Color("Gray"))
                    .cornerRadius(17)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

struct AccountTypeDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountTypeDetailsView(header: "Заголовок", accounts: .constant([Account(accountGroupID: 1, accounting: true, currencySignatura: "USD", iconID: 0, id: 0, name: "Название счета", remainder: 123.456, typeSignatura: "debt", userID: 1, visible: true)]))
    }
}
