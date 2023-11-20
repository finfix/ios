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
    @State var gradualBudgetFilling: Bool
    
    init(isUpdateOpen: Binding<Bool>, account: Account) {
        self._isUpdateOpen = isUpdateOpen
        self.oldAccount = account
        self.id = account.id
        self.accounting = account.accounting
        self.visible = account.visible
        self.budget = account.budget.stringValue
        self.name = account.name
        self.remainder = account.remainder.stringValue
        self.gradualBudgetFilling = account.gradualBudgetFilling
    }
    
    var body: some View {
        Form {
            TextField("Название", text: $name)
            if oldAccount.childrenAccounts.isEmpty {
                TextField("Бюджет", text: $budget)
                TextField("Остаток", text: $remainder)
            #if !os(macOS)
                    .keyboardType(.decimalPad)
            #endif
            }
            Toggle(isOn: $accounting) {
                Text("Подсчитывать ли счет в шапке")
            }
            Toggle(isOn: $visible) {
                Text("Показывать ли счет")
            }
            Toggle(isOn: $gradualBudgetFilling) {
                Text("Плавное заполнение бюджета")
            }
            Section {
                Button("Сохранить") {
                    updateAccount()
                    isUpdateOpen = false
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func updateAccount() {
        
        Task {
            var req = UpdateAccountReq(id: id)
            if oldAccount.visible != visible {
                req.visible = visible
                //            modelData.accountsGrouped[accountIndex].visible = visible
            }
            if oldAccount.accounting != accounting {
                req.accounting = accounting
                //            modelData.accountsGrouped[accountIndex].accounting = accounting
            }
            if oldAccount.gradualBudgetFilling != gradualBudgetFilling {
                req.gradualBudgetFilling = gradualBudgetFilling
                //            modelData.accountsGrouped[accountIndex].accounting = accounting
            }
            if oldAccount.remainder.stringValue != self.remainder {
                let remainder = Double(self.remainder.replacingOccurrences(of: ",", with: "."))
                req.remainder = remainder
                //            modelData.accountsGrouped[accountIndex].remainder = remainder!
            }
            if oldAccount.budget.stringValue != self.budget {
                let budget = Double(self.budget.replacingOccurrences(of: ",", with: "."))
                req.budget = budget
                //            modelData.accountsGrouped[accountIndex].budget = budget!
            }
            if oldAccount.name != name {
                req.name = name
                //            modelData.accountsGrouped[accountIndex].name = name
            }
            do {
                try await AccountAPI().UpdateAccount(req: req)
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    UpdateAccount(isUpdateOpen: .constant(true), account: Account())
}
