//
//  SelectAccountGroup.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "account group selector")

struct AccountGroupSelector: View {
    
    @Query var accountGroups: [AccountGroup]
    @AppStorage("accountGroupIndex") var selectedAccountGroupIndex: Int = 0 {
        didSet {
            guard accountGroups.count >= selectedAccountGroupIndex + 1 else { return }
            logger.info("Выбрали группу счетов \(accountGroups[selectedAccountGroupIndex].name, privacy: .private)")
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
        .onAppear {
            if selectedAccountGroupIndex + 1 > accountGroups.count {
                selectedAccountGroupIndex = 0
            }
        }
    }
}

#Preview {
    AccountGroupSelector()
        .modelContainer(previewContainer)
}
