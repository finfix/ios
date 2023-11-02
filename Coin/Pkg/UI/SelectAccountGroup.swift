//
//  SelectAccountGroup.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import SwiftData

struct AccountsGroupSelector: View {
    
    @Query var accountGroups: [AccountGroup]
    @AppStorage("accountGroupIndex") var selectedAccountsGroupIndex: Int = 0
    
    var canForward: Bool {
        selectedAccountsGroupIndex + 1 < accountGroups.count
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
            
            Text(accountGroups.count > 0 ? accountGroups[selectedAccountsGroupIndex].name : "")
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
}
