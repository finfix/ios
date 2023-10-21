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
    
    var totalSum: Double {
        var total = 0.0
        for account in accounts {
            total += account.remainder
        }
        return total
    }
    
    var accounts: [Account]
    
    var body: some View {
        VStack {
            // Заголовок с общей суммой
            Button {
                withAnimation {
                    showingList.toggle()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(showingList ? 90 : 0))
                Text(header)
                Spacer()
                Text("\(String(format: "%.0f", totalSum))")
            }
            .foregroundColor(.primary)
            .padding()
            // Список счетов
            if showingList {
                ForEach(accounts, id: \.id) { account in
                    HStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.gray)
                        Text(account.name)
                            .lineLimit(1)
                        Spacer()
                        Text("\(String(format: "%.2f", account.remainder)) \(account.currencySymbol)")
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

#Preview {
    AccountTypeDetailsView(header: "Заголовок", accounts: [Account(id: 1, accountGroupID: 1, accounting: true, budget: 0, currency: "Rub", iconID: 3, name: "Some", remainder: 3, type: .expense, visible: true, parentAccountID: nil, childrenAccounts: nil, currencySymbol: "")])
}
