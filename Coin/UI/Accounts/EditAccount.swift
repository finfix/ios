//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment (AlertManager.self) private var alert

    @State private var vm: EditAccountViewModel
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    var selectedAccountGroup: AccountGroup
    
    var accounts: [Account] {
        vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup
        }
    }
        
    init(_ account: Account, selectedAccountGroup: AccountGroup, isHiddenView: Bool = false) {
        vm = EditAccountViewModel(
            currentAccount: account,
            oldAccount: account,
            mode: .update,
            isHiddenView: isHiddenView
        )
        self.selectedAccountGroup = selectedAccountGroup
    }
    
    init(accountType: AccountType, accountGroup: AccountGroup) {
        vm = EditAccountViewModel(
            currentAccount: Account(
                type: accountType,
                accountGroup: accountGroup
            ),
            mode: .create
        )
        self.selectedAccountGroup = accountGroup
    }
        
    var body: some View {
        Form {
            if vm.mode == .create {
                Section {
                    Picker("", selection: $vm.currentAccount.isParent) {
                        Text("Обычный счет")
                            .tag(false)
                        Text("Родительский счет")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            Section {
                
                TextField("Название счета", text: $vm.currentAccount.name)
                
                if vm.permissions.changeRemainder {
                    TextField(vm.mode == .create ? "Начальный баланс" : "Баланс", value: $vm.currentAccount.remainder, format: .number)
                        .keyboardType(.decimalPad)
                }
                
            }
            
            if vm.permissions.changeBudget {
                Section(header: Text("Бюджет")) {
                    if vm.currentAccount.showingBudgetAmount != vm.currentAccount.budgetAmount {
                        Text(vm.currentAccount.showingBudgetAmount, format: .number)
                            .foregroundColor(.secondary)
                    }
                    TextField("Бюджет", value: $vm.currentAccount.budgetAmount, format: .number)
                        .keyboardType(.decimalPad)
                    if vm.currentAccount.budgetAmount != 0 {
                        TextField("Фиксированная сумма", value: $vm.currentAccount.budgetFixedSum, format: .number)
                            .keyboardType(.decimalPad)
                        if vm.currentAccount.budgetFixedSum != 0 {
                            TextField("Отступ в днях", value: $vm.currentAccount.budgetDaysOffset, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                    Toggle("Плавное заполнение бюджета", isOn: $vm.currentAccount.budgetGradualFilling)
                }
            }
            
            Section {
                
                Toggle("Учитывать ли счет в шапке", isOn: $vm.currentAccount.accountingInHeader)
                    .disabled(!vm.currentAccount.visible)
                Toggle("Учитывать ли счет на графиках", isOn: $vm.currentAccount.accountingInCharts)
                if vm.mode == .update {
                    Toggle("Видимость счета", isOn: $vm.currentAccount.visible)
                }
                
                if vm.mode == .create || vm.permissions.changeCurrency {
                    Picker("Валюта", selection: $vm.currentAccount.currency) {
                        ForEach(vm.currencies) { currency in
                            Text(currency.code)
                                .tag(currency)
                        }
                    }
                }
                Picker(selection: $vm.currentAccount.icon) {
                    ForEach(vm.icons) { icon in
                        HStack {
                            Text(icon.name)
                            AsyncImage(url: URL.documentsDirectory.appending(path: String(icon.url))) { image in
                                image.image?
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                            }
                        }
                        .tag(icon)
                    }
                } label: {
                    Text("Иконка")
                }
                .pickerStyle(.wheel)

            }
            Section {
                if vm.mode == .update {
                    Picker("Счет, перед которым стоит этот счет", selection: $vm.currentAccount.serialNumber) {
                        ForEach(vm.currentAccount.parentAccountID == nil ? Account.groupAccounts(accounts) : accounts.filter{ $0.parentAccountID == vm.currentAccount.parentAccountID! }) { account in
                            Text(vm.currentAccount.parentAccountID == nil ? account.name : "\(account.name) \(account.currency.symbol)")
                                .tag(account.serialNumber - 1)
                        }
                    }
                    if vm.permissions.changeParentAccountID {
                        Section {
                            Picker("Родительский счет", selection: $vm.currentAccount.parentAccountID) {
                                Text("Не выбрано")
                                    .tag(nil as UInt32?)
                                ForEach(accounts.filter{ $0.isParent }) { account in
                                    Text(account.name)
                                        .tag(account.id as UInt32?)
                                }
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    Task {
                        shouldDisableUI = true
                        shouldShowProgress = true
                        defer {
                            shouldDisableUI = false
                            shouldShowProgress = false
                        }
                        
                        do {
                            switch vm.mode {
                            case .create:
                                try await vm.createAccount()
                            case .update:
                                try await vm.updateAccount()
                            }
                        } catch {
                            alert(error)
                            return
                        }
                        
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
            if vm.currentAccount.id != 0 {
                Section(footer:
                    VStack(alignment: .leading) {
                        Text("ID: \(vm.currentAccount.id)")
                        Text("Дата и время создания: \(vm.currentAccount.datetimeCreate, format: .dateTime)")
                    }
                ) {}
            }
        }
        .onChange(of: vm.currentAccount.visible) { _, newValue in
            if !newValue {
                vm.currentAccount.accountingInHeader = false
            }
        }
        .navigationTitle(vm.mode == .create ? "Cоздание счета" : "Изменение счета")
        .task {
            do {
                try await vm.load()
                if vm.mode == .create && vm.currentAccount.currency != Currency() {
                    vm.currentAccount.currency = vm.currencies.first(where: { $0 == selectedAccountGroup.currency }) ?? Currency()
                }
            } catch {
                alert(error)
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button(role: .destructive) {
                    Task {
                        shouldDisableUI = true
                        shouldShowProgress = true
                        defer {
                            shouldDisableUI = false
                            shouldShowProgress = false
                        }
                        
                        do {
                            try await vm.deleteAccount()
                        } catch {
                            alert(error)
                            return
                        }
                        
                        dismiss()
                    }
                } label: {
                    if shouldShowProgress {
                        ProgressView()
                    } else {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        })
        .disabled(shouldDisableUI)
    }
}

#Preview {
    EditAccount(accountType: .regular, accountGroup: AccountGroup())
        .environment(AlertManager(handle: {_ in }))
}
