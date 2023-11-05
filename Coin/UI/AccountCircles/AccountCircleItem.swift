//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct AccountCircleItem: View {
    
    var account: Account
    
    @Query var currencies: [Currency]
    
    @State var isChildrenOpen = false
    @State var isUpdateOpen = false
    
    var alreadyOpened = false
    
    var currenciesMap: [String: Currency] {
        Dictionary(uniqueKeysWithValues: currencies.map{ ($0.isoCode, $0) })
    }
    
    var currencySymbol: String {
        currenciesMap[account.currency]?.symbol ?? ""
    }
    
    var formatter: CurrencyFormatter
    
    init(account: Account, alreadyOpened: Bool = false) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        self.alreadyOpened = alreadyOpened
    }
    
    var body: some View {
        
        VStack {
            Text(account.name)
                .lineLimit(1)
            
            ZStack {
                if !account.childrenAccounts.isEmpty {
                    Circle()
                        .fill(.clear)
                        .strokeBorder(account.showingBudget == 0 ? .gray : account.showingBudget >= account.showingRemainder ? .green : .red, lineWidth: 1)
                        .frame(width: 35)
                }
                Circle()
                    .fill(account.showingBudget == 0 ? .gray : account.showingBudget >= account.showingRemainder ? .green : .red)
                    .frame(width: 30)
                
                    .onTapGesture(count: 2) {
                        if !alreadyOpened {
                            isChildrenOpen = true
                        }
                    }
                    .onLongPressGesture(minimumDuration: 1.0) {
                        isUpdateOpen = true
                    }
            }
            Text(formatter.string(number: account.remainder))
                .lineLimit(1)
            
            if account.showingBudget != 0 {
                Text(formatter.string(number: account.showingBudget))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .frame(width: 80, height: 100)
        .opacity(account.accounting ? 1 : 0.5)
        .popover(isPresented: $isChildrenOpen) {
            ForEach(account.childrenAccounts) { childAccount in
                AccountCircleItem(account: childAccount, alreadyOpened: true)
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
        .navigationDestination(isPresented: $isUpdateOpen) {
            UpdateAccount(isUpdateOpen: $isUpdateOpen, account: account)
        }
    }
}

#Preview {
    AccountCircleItem(account: Account(
        id: 1,
        accountGroupID: 1,
        accounting: true,
        budget: 49,
        currency: "RUB",
        iconID: 1,
        name: "parent",
        remainder: 34,
        type: .expense,
        visible: true,
        parentAccountID: nil,
        childrenAccounts: [
            Account(
                id: 2,
                accountGroupID: 1,
                accounting: true,
                budget: 0,
                currency: "RUB",
                iconID: 1,
                name: "child",
                remainder: 43,
                type: .expense,
                visible: true,
                parentAccountID: nil),
            Account(
                id: 3,
                accountGroupID: 1,
                accounting: true,
                budget: 34,
                currency: "RUB",
                iconID: 1,
                name: "child",
                remainder: 43,
                type: .expense,
                visible: true,
                parentAccountID: nil),
            Account(
                id: 4,
                accountGroupID: 1,
                accounting: true,
                budget: 34,
                currency: "RUB",
                iconID: 1,
                name: "child",
                remainder: 43,
                type: .expense,
                visible: true,
                parentAccountID: nil)]))
}
