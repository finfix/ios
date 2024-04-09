//
//  HidedAccountsList.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import SwiftUI

struct HidedAccountsList: View {
    
    @State private var vm = HidedAccountViewModel()
    @Binding var selectedAccountGroup: AccountGroup
    @Binding var path: NavigationPath
    
    var accounts: [Account] {
        vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AccountGroupSelector(selectedAccountGroup: $selectedAccountGroup)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(accounts) { account in
                        AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                    }
                }
            }
        }
        .navigationDestination(for: Account.self) { EditAccount($0, selectedAccountGroup: selectedAccountGroup) }
        .contentMargins(.horizontal, 10, for: .automatic)
        .toolbar {
            Picker("Тип счета", selection: $vm.type) {
                ForEach(AccountType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .tag(value)
                }
            }        
            .onChange(of: vm.type) {
                vm.load()
            }
        }
        .task {
            vm.load()
        }
    }
}

#Preview {
    HidedAccountsList(selectedAccountGroup: .constant(AccountGroup()), path: .constant(NavigationPath()))
}
