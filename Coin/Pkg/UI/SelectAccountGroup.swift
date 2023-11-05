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
    @AppStorage("accountGroupIndex") var selectedAccountGroupIndex: Int = 0 {
        didSet {
            guard accountGroups.count >= selectedAccountGroupIndex + 1 else { return }
            debugLog("\nВыбрали группу счетов \(accountGroups[selectedAccountGroupIndex].name)")
            selectedAccountGroupID = Int(accountGroups[selectedAccountGroupIndex].id)
        }
    }
    @AppStorage("accountGroupID") var selectedAccountGroupID: Int?
    
    var canForward: Bool {
        selectedAccountGroupIndex + 1 < accountGroups.count
    }
    
    var canBackward: Bool {
        selectedAccountGroupIndex > 0
    }
    
    var body: some View {
        HStack(spacing: 80) {
            Button {
                if canBackward {
                    selectedAccountGroupIndex -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(canBackward ? .primary : .gray)
            }
            
            Text(accountGroups.count > 0 ? accountGroups[selectedAccountGroupIndex].name : "")
                .frame(width: 100)
            
            Button {
                if canForward {
                    selectedAccountGroupIndex += 1
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
