//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItem: View {
    
    var account: Account
    
    @Environment(ModelData.self) var modelData
    
    @State var isChildrenOpen = false
    @State var isUpdateOpen = false
    
    var currencySymbol: String {
        modelData.currencies[account.currency]?.symbol ?? ""
    }
    
    var body: some View {
        
        VStack {
            Text(account.name)
                .lineLimit(1)
            
            Circle()
                .frame(width: 30)
                .foregroundColor(account.budget == 0 ? .gray : account.budget >= account.remainder ? .green : .red)
                .onTapGesture {
                    isChildrenOpen = true
                }
                .onLongPressGesture(minimumDuration: 1.0) {
                    isUpdateOpen = true
                }
            
            Text(currencyFormat(amount: account.remainder, currencyCode: currencySymbol))
                .lineLimit(1)
            
            if account.budget != 0 {
                Text(currencyFormat(amount: account.budget, currencyCode: currencySymbol))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .frame(width: 80, height: 100)
        .popover(isPresented: $isChildrenOpen) {
            if account.childrenAccounts.count > 0 {
                AccountChildren(children: account.childrenAccounts)
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        }
        .navigationDestination(isPresented: $isUpdateOpen) {
            UpdateAccount(isUpdateOpen: $isUpdateOpen, account: account)
        }
        
    }
}

func currencyFormat(amount: Double, currencyCode: String) -> String {
    var num = amount
    
    let sign = ((num < 0) ? "-" : "" );
    
    num = fabs(num)
    
    if (num < 1000000.0){
        return "\(sign)\(round(num)) \(currencyCode)"
    }
    
    let exp:Int = Int(log10(num) / 6.0 )
    
    let units:[String] = ["k","M","G","T","P","E"]
    
    let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10
    
    return "\(sign)\(roundedNum)\(units[exp-1]) \(currencyCode)"
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
