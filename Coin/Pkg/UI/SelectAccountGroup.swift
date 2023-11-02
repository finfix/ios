//
//  SelectAccountGroup.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountsGroupSelector: View {
    
    @Environment(ModelData.self) var modelData
    
    @AppStorage("accountGroupIndex") var selectedAccountsGroupIndex: Int = 0
    
    var canForward: Bool {
        selectedAccountsGroupIndex + 1 < modelData.accountGroups.count
    }
    
    var canBackward: Bool {
        selectedAccountsGroupIndex > 0
    }
    
    var body: some View {
        HStack(spacing: 80) {
            Button {
                if canBackward {
                    selectedAccountsGroupIndex -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(canBackward ? .primary : .gray)
            }
            
            Text("\(modelData.accountGroups.count > 0 ? modelData.accountGroups[selectedAccountsGroupIndex].name : "")")
                .frame(width: 100)
            
            Button {
                if canForward {
                    selectedAccountsGroupIndex += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(canForward ? .primary : .gray)
            }
        }
        .padding()
    }
}

#Preview {
    AccountsGroupSelector()
        .environment(ModelData())
}
