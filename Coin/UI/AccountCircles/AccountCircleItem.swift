//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItem: View {
    
    var account: Account
    
    @State var isChildrenOpen = false
    @State var isUpdateOpen = false
    
    var body: some View {
        ZStack {
            VStack {
                Text(account.name)
                    .lineLimit(1)
                    .font(.footnote)
                
                Circle()
                    .frame(width: 30)
                    .foregroundColor(account.budget == 0 ? .gray : account.budget >= account.remainder ? .green : .red)
                    .onTapGesture {
                        isChildrenOpen = true
                    }
                    .onLongPressGesture(minimumDuration: 1.0) {
                        isUpdateOpen = true
                    }
                
                Text("\(String(format: "%.2f", account.remainder)) \(account.currencySymbol)")
                    .lineLimit(1)
                    .font(.footnote)
                
                if account.budget != 0 {
                    Text("\(String(format: "%.0f", account.budget)) \(account.currencySymbol)")
                        .lineLimit(1)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            if isChildrenOpen && account.childrenAccounts != nil {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color("StrongGray"))
                HStack {
                    ForEach(account.childrenAccounts!) { childAccount in
                        AccountCircleItem(account: childAccount)
                    }
                }
                .onTapGesture {
                    isChildrenOpen = false
                }
            }
        }
        .frame(width: 70, height: 110)
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
                parentAccountID: nil,
                childrenAccounts: nil,
                currencySymbol: "$"),
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
                parentAccountID: nil,
                childrenAccounts: nil,
                currencySymbol: "$"),
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
                parentAccountID: nil,
                childrenAccounts: nil,
                currencySymbol: "$")],
        currencySymbol: "$"))
}
