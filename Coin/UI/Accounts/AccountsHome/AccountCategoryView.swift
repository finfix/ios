//
//  HeaderListAccountType.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountCategoryView: View {
    
    @State var header: String
    @State var showingList = false
    
    var totalSum: Decimal {
        var total: Decimal = 0
        for account in accounts {
            total += account.remainder
        }
        return total
    }
    
    var currencyFormatter = CurrencyFormatter(maximumFractionDigits: 0)
    
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
                // TODO: Сделать динамическим
                Text("Сумма")
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
                        Text(CurrencyFormatter().string(number: account.showingRemainder, currency: account.currency))
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
    AccountCategoryView(header: "Заголовок", accounts: [])
        .environment(AlertManager(handle: {_ in }))
}
