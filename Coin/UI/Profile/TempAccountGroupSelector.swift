//
//  TempAccountGroupSelector.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import SwiftUI

struct TempAccountGroupSelector: View {
    
    private var vm = AccountGroupSelectorViewModel()

    @AppStorage("accountGroupID") var selectedAccountGroupID: Int?
    @State var selectedAccountGroup = AccountGroup()
        
    var body: some View {
        Picker("Группа счетов", selection: $selectedAccountGroup) {
            ForEach(vm.accountGroups) { accountGroup in
                Text(accountGroup.name)
                    .tag(accountGroup)
            }
        }
        .pickerStyle(.segmented)
        Button {
            selectedAccountGroupID = Int(selectedAccountGroup.id)
        } label: {
            Text("...")
        }
        .task {
            vm.load()
        }
    }
}

#Preview {
    TempAccountGroupSelector()
}
