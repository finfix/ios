//
//  SelectAccountGroup.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "account group selector")

struct AccountGroupSelector: View {
    
    private var vm = AccountGroupSelectorViewModel()
    @AppStorage("accountGroupIndex") var selectedAccountGroupIndex: Int = 0 {
        didSet {
            guard vm.accountGroups.count >= selectedAccountGroupIndex + 1 else { return }
            logger.info("Выбрали группу счетов \(vm.accountGroups[selectedAccountGroupIndex].name, privacy: .private)")
            selectedAccountGroupID = Int(vm.accountGroups[selectedAccountGroupIndex].id)
        }
    }
    @AppStorage("accountGroupID") var selectedAccountGroupID: Int?
    
    var canForward: Bool {
        selectedAccountGroupIndex + 1 < vm.accountGroups.count
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
            
            Text(vm.accountGroups.count > 0 ? vm.accountGroups[selectedAccountGroupIndex].name : "")
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
        .task {
            vm.load()
        }
        .padding()
    }
}

#Preview {
    AccountGroupSelector()
}
