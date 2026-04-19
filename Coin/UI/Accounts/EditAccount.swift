//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import Factory

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(AlertManager.self) private var alert

    @State private var vm: EditAccountViewModel
    
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
                accountGroup: accountGroup,
                currency: accountGroup.currency
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
                    TextField(vm.mode == .create ? "Начальный баланс" : "Баланс", value: $vm.remainder, formatter: NumberFormatters.textField)
                        .keyboardType(.decimalPad)
                        .overlay(alignment: .trailing) {
                            Text(vm.currentAccount.currency.symbol)
                        }
                }
                
            }
            
            if vm.permissions.changeBudget {
                Section(header: Text("Бюджет")) {
                    TextField("Бюджет", value: $vm.budgetAmount, formatter: NumberFormatters.textField)
                        .keyboardType(.decimalPad)
                        .overlay(alignment: .trailing) {
                            Text(vm.currentAccount.currency.symbol)
                        }
                    if vm.currentAccount.budgetAmount != 0 {
                        TextField("Фиксированная сумма", value: $vm.budgetFixedSum, formatter: NumberFormatters.textField)
                            .keyboardType(.decimalPad)
                            .overlay(alignment: .trailing) {
                                Text(vm.currentAccount.currency.symbol)
                            }
                        if vm.currentAccount.budgetFixedSum != 0 {
                            TextField("Отступ в днях", value: $vm.currentAccount.budgetDaysOffset, formatter: NumberFormatters.textField)
                                .keyboardType(.numberPad)
                                .overlay(alignment: .trailing) {
                                    Text("дней")
                                }
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
                NavigationLink("Иконка", destination: IconPicker(selectedIcon: $vm.currentAccount.icon))
            }
            Section {
                if vm.mode == .update {
                    Picker("Счет, перед которым стоит этот счет", selection: $vm.currentAccount.serialNumber) {
                        ForEach(vm.currentAccount.parentAccountID == nil ? Account.groupAccounts(accounts) : accounts.filter{ $0.parentAccountID == vm.currentAccount.parentAccountID! }) { account in
                            Text(vm.currentAccount.parentAccountID == nil ? account.name : "\(account.name) \(account.currency.symbol)")
                                .tag(account.serialNumber == 0 ? 0 : account.serialNumber - 1)
                        }
                    }
                }
                if vm.permissions.changeParentAccountID {
                    Section {
                        Picker("Родительский счет", selection: $vm.currentAccount.parentAccountID) {
                            Text("Не выбрано")
                                .tag(nil as UUID?)
                            ForEach(accounts.filter{ $0.isParent }) { account in
                                Text(account.name)
                                    .tag(account.id as UUID?)
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    Task {
                        do {
                            switch vm.mode {
                            case .create:
                                try await vm.createAccount()
                            case .update:
                                try await vm.updateAccount()
                            }
                        } catch {
                            alert.error(error)
                            return
                        }
                        
                        dismiss()
                    }
                } label: {
                    Text("Сохранить")
                }
                .frame(maxWidth: .infinity)
            }
            if vm.currentAccount.id != UUID(uuid: UUID_NULL) {
                Section {
                    NavigationLink {
                        TransactionsView(
                            filters: TransactionFilters(
                                accounts: [vm.currentAccount],
                                accountGroups: [selectedAccountGroup]
                            ),
                            chartType: vm.currentAccount.type == .earnings ? .earnings : 
                                      vm.currentAccount.type == .expense ? .expenses : .earningsAndExpenses
                        )
                    } label: {
                        Label("Просмотреть все транзакции", systemImage: "list.bullet")
                    }
                }
                
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
                try await vm.load(accountGroup: selectedAccountGroup)
                if vm.mode == .create && vm.currentAccount.currency != Currency() {
                    vm.currentAccount.currency = vm.currencies.first(where: { $0 == selectedAccountGroup.currency }) ?? Currency()
                }
            } catch {
                alert.error(error)
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await vm.deleteAccount()
                        } catch {
                            alert.error(error)
                            return
                        }
                        
                        dismiss()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        })
    }
}

#Preview("Создание счета") {
        EditAccount(
            accountType: .expense,
            accountGroup:
                AccountGroup(
                    currency:
                        Currency(
                            symbol: "$"
                        )
                )
        )
        .environment(AlertManager(handle: {_ in }))
}

#Preview("Редактирование счета") {
    EditAccount(
        Account(
            accountingInHeader: true,
            accountingInCharts: true,
            icon: Icon(id: UUID()),
            name: "Тестовый счет",
            type: .expense,
            visible: true,
            serialNumber: 2,
            isParent: false,
            budgetAmount: 1000,
            showingBudgetAmount: 1000,
            budgetFixedSum: 500,
            budgetDaysOffset: 5,
            budgetGradualFilling: true,
            datetimeCreate: Date.now,
            accountGroup: AccountGroup(id: UUID()),
            currency: Currency(symbol: "$")
        ),
        selectedAccountGroup: AccountGroup(),
        isHiddenView: false
    )
    .environment(AlertManager(handle: {_ in }))
}

struct IconPicker: View {
    
    @Injected(\.service) private var service
    
    @State var icons: [Icon] = []
    @Environment(\.dismiss) var dismiss

    @Binding var selectedIcon: Icon
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                ForEach(icons) { icon in
                    Button {
                        selectedIcon = icon
                        dismiss()
                    } label: {
                        Circle()
                            .fill(.orange)
                            .frame(height: 60)
                            .overlay{
                                AsyncImage(url: URL.documentsDirectory.appending(path: icon.url)) { image in
                                    image.image?
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30)
                                }
                            }
                    }
                }
            }
        }
        .task {
            do {
                self.icons = try await service.getIcons()
            } catch {
                
            }
        }
    }
}
