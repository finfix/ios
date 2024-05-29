//
//  HidedAccountsList.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import SwiftUI

struct HidedAccountsList: View {
    
    @Environment (AlertManager.self) private var alert
    @State private var vm = HidedAccountViewModel()
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @Environment(PathSharedState.self) var path
    
    var accounts: [Account] {
        vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup.selectedAccountGroup
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AccountGroupSelector()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(accounts) { account in
                        AccountCircleItem(account)
                    }
                }
            }
        }
        .navigationDestination(for: Account.self) { EditAccount($0, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup, isHiddenView: true) }
        .contentMargins(.horizontal, 10, for: .automatic)
        .toolbar {
            Picker("Тип счета", selection: $vm.type) {
                ForEach(AccountType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .tag(value)
                }
            }
            .onChange(of: vm.type) {
                Task {
                    do {
                        try await vm.load()
                    } catch {
                        alert(error)
                    }
                }
            }
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    HidedAccountsList()
        .environment(AlertManager(handle: {_ in }))
}
