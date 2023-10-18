//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountCircleList: View {
    
    @Environment(ModelData.self) var modelData
    
    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            Header()
            ScrollView(.horizontal) {
                HStack {
                    CirclesArray(accounts: modelData.accountsGrouped.filter { ($0.type == .earnings) && $0.visible })
                }
            }.frame(maxHeight: 100)
            
            Divider()
            
            ScrollView(.horizontal) {
                HStack {
                    CirclesArray(accounts: modelData.accountsGrouped.filter { ($0.type != .earnings) && ($0.type != .expense) && $0.visible })
                }
            }.frame(maxHeight: 100)
            
            Divider()
            
            ScrollView(.horizontal) {
                LazyHGrid(rows: rows) {
                    CirclesArray(accounts: modelData.accountsGrouped.filter {($0.type == .expense) && $0.visible })
                }
            }
            .frame(maxHeight: .infinity)
            Spacer()
        }
        .onAppear(perform: modelData.getAccountsGrouped)
    }
}

#Preview {
    AccountCircleList()
}
