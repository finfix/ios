//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var vm: EditAccountViewModel
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
        
    init(_ account: Account) {
        vm = EditAccountViewModel(
            currentAccount: account,
            oldAccount: account,
            mode: .update
        )
    }
    
    init(accountType: AccountType, accountGroup: AccountGroup) {
        vm = EditAccountViewModel(
            currentAccount: Account(
                type: accountType,
                accountGroup: accountGroup
            ),
            mode: .create
        )
    }
        
    var body: some View {
        Form {
            Section {
                
                TextField("Название счета", text: $vm.currentAccount.name)
                
                if vm.permissions.changeRemainder {
                    TextField(vm.mode == .create ? "Начальный баланс" : "Баланс", value: $vm.currentAccount.remainder, format: .number)
                        .keyboardType(.decimalPad)
                }
                
            }
            
            if vm.permissions.changeBudget {
                Section(header: Text("Бюджет")) {
                    TextField("Бюджет", value: $vm.currentAccount.budgetAmount, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Фиксированная сумма", value: $vm.currentAccount.budgetFixedSum, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Отступ в днях", value: $vm.currentAccount.budgetDaysOffset, format: .number)
                        .keyboardType(.numberPad)
                    Toggle("Плавное заполнение бюджета", isOn: $vm.currentAccount.budgetGradualFilling)
                }
            }
            
            Section {
                
                Toggle("Учитывать ли счет в шапке", isOn: $vm.currentAccount.accounting)
                if vm.mode == .update {
                    Toggle("Видимость счета", isOn: $vm.currentAccount.visible)
                }
                
                
                
                if vm.mode == .create {
                    Picker("Валюта", selection: $vm.currentAccount.currency) {
                        ForEach(vm.currencies, id: \.code) { currency in
                            Text(currency.code)
                                .tag(currency)
                        }
                    }
                }
            }
            Section {
                Button {
                    Task {
                        shouldDisableUI = true
                        shouldShowProgress = true
                        
                        switch vm.mode {
                        case .create:
                            await vm.createAccount()
                        case .update:
                            await vm.updateAccount()
                        }
                        
                        shouldDisableUI = false
                        shouldShowProgress = false
                        
                        dismiss()
                    }
                } label: {
                    if shouldShowProgress {
                        ProgressView()
                    } else {
                        Text("Сохранить")
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(vm.mode == .create ? "Cоздание счета" : "Изменение счета")
        .task {
            vm.load()
        }
        .disabled(shouldDisableUI)
    }
}

#Preview {
    EditAccount(accountType: .regular, accountGroup: AccountGroup())
}
