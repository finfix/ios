//
//  UpdateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct UpdateAccount: View {
    
    @Binding var isUpdateOpen: Bool
    @Environment(ModelData.self) var modelData
        
    var oldAccount: Account
    var id: UInt32
    @State var accounting: Bool
    @State var visible: Bool
    @State var budget: String
    @State var name: String
    @State var remainder: String
    
    init(isUpdateOpen: Binding<Bool>, account: Account) {
        self._isUpdateOpen = isUpdateOpen
        self.oldAccount = account
        self.id = account.id
        self.accounting = account.accounting
        self.visible = account.visible
        self.budget = String(account.budget)
        self.name = account.name
        self.remainder = String(account.remainder)
    }
    
    var body: some View {
        Form {
            TextField("Название", text: $name)
            if oldAccount.childrenAccounts.isEmpty {
                TextField("Бюджет", text: $budget)
                TextField("Остаток", text: $remainder)
                    .keyboardType(.decimalPad)
            }
            Toggle(isOn: $accounting) {
                Text("Подсчитывать ли счет в шапке")
            }
            Toggle(isOn: $visible) {
                Text("Показывать ли счет")
            }
        }
        Button("Сохранить") {
            updateAccount()
            isUpdateOpen = false
        }
    }
    
    func updateAccount() {
        
        var req = UpdateAccountReq(id: id)
        if oldAccount.visible != visible {
            req.visible = visible
//            modelData.accountsGrouped[accountIndex].visible = visible
        }
        if oldAccount.accounting != accounting {
            req.accounting = accounting
//            modelData.accountsGrouped[accountIndex].accounting = accounting
        }
        if String(oldAccount.remainder) != self.remainder {
            let remainder = Double(self.remainder.replacingOccurrences(of: ",", with: "."))
            req.remainder = remainder
//            modelData.accountsGrouped[accountIndex].remainder = remainder!
        }
        if String(oldAccount.budget) != self.budget {
            let budget = Double(self.budget.replacingOccurrences(of: ",", with: "."))
            req.budget = budget
//            modelData.accountsGrouped[accountIndex].budget = budget!
        }
        if oldAccount.name != name {
            req.name = name
//            modelData.accountsGrouped[accountIndex].name = name
        }
        
        AccountAPI().UpdateAccount(req: req) { error in
            if let err = error {
                showErrorAlert(error: err)
            }
        }
    }
}

#Preview {
    UpdateAccount(isUpdateOpen: .constant(true), account: Account(id: 1, accountGroupID: 1, accounting: true, budget: 1000.4, currency: "RUB", iconID: 1, name: "Надо поменять", remainder: 23, type: .regular, visible: false, parentAccountID: nil))
}
