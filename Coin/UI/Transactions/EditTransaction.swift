//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditTransaction")

enum EditTransactionRoute: Hashable {
    case tagsList
}

struct Tags: View {
    
    var vm: EditTransactionViewModel
    @Environment(PathSharedState.self) var path
    
    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                VStack(alignment: .leading) {
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            if i % 2 == 0 {
                                Button {
                                    withAnimation {
                                        if vm.currentTransaction.tags.contains(tag) {
                                            vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                        } else {
                                            vm.currentTransaction.tags.append(tag)
                                        }
                                    }
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 100)
                                                .foregroundStyle(vm.currentTransaction.tags.contains(tag) ? Color.blue : Color.clear)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 100)
                                                        .stroke(.secondary, lineWidth: 1)
                                                }
                                        }
                                }
                            }
                        }
                    }
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            if i % 2 != 0 {
                                Button {
                                    withAnimation {
                                        if vm.currentTransaction.tags.contains(tag) {
                                            vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                        } else {
                                            vm.currentTransaction.tags.append(tag)
                                        }
                                    }
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 100)
                                                .foregroundStyle(vm.currentTransaction.tags.contains(tag) ? Color.blue : Color.clear)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 100)
                                                        .stroke(.secondary, lineWidth: 1)
                                                }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(1)
            }
            Button {
                path.path.append(EditTransactionRoute.tagsList)
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .buttonStyle(.plain)
    }
}

struct EditTransaction: View {
    
    private enum Field: Hashable {
        case amountFromSelector, amountToSelector, note
    }
    @FocusState private var focusedField: Field?
    
    @Environment(\.dismiss) private var dismiss
    @State private var vm: EditTransactionViewModel
    @Environment(AlertManager.self) private var alert
    
    @Environment(PathSharedState.self) var path
    
    init(_ transaction: Transaction) {
        vm = EditTransactionViewModel(
            currentTransaction: transaction,
            oldTransaction: transaction,
            accountGroup: transaction.accountFrom.accountGroup,
            mode: .update
        )
    }
    
    init(
        transactionType: TransactionType,
        accountFrom: Account = Account(),
        accountTo: Account = Account(),
        accountGroup: AccountGroup
    ) {
        vm = EditTransactionViewModel(
            currentTransaction: Transaction(
                accountingInCharts: true, 
                type: transactionType,
                accountFrom: accountFrom,
                accountTo: accountTo
            ),
            accountGroup: accountGroup,
            mode: .create
        )
    }
    
    var body: some View {
        Form {
            Section {
                Tags(vm: vm)
            }
            if vm.currentTransaction.type != .balancing {
                Section {
                    Pickers(
                        isPickerShowing: $vm.shouldShowPickerAccountFrom,
                        buttonName: "Счет списания",
                        account: $vm.currentTransaction.accountFrom,
                        accounts: vm.accounts,
                        position: .up,
                        transactionType: vm.currentTransaction.type
                    )
                    .onChange(of: vm.currentTransaction.accountFrom) { _, newValue in
                        guard newValue.id != 0 else { return }
                        withAnimation {
                            vm.shouldShowPickerAccountFrom = false
                            vm.shouldShowPickerAccountTo = true
                        }
                    }
                    Pickers(
                        isPickerShowing: $vm.shouldShowPickerAccountTo,
                        buttonName: "Счет пополнения",
                        account: $vm.currentTransaction.accountTo,
                        accounts: vm.accounts,
                        position: .down,
                        transactionType: vm.currentTransaction.type,
                        excludeAccount: vm.currentTransaction.accountFrom
                    )
                    .onChange(of: vm.currentTransaction.accountTo) { _, newValue in
                        guard newValue.id != 0 else { return }
                        withAnimation {
                            vm.shouldShowPickerAccountTo = false
                            focusedField = .amountFromSelector
                        }
                    }
                }
                .pickerStyle(.wheel)
            }
            Section {
                if vm.currentTransaction.type != .balancing {
                    TextField(
                        vm.intercurrency ? "Сумма списания" : "Сумма",
                        value: $vm.amountFrom,
                        formatter: NumberFormatters.textField
                    )
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amountFromSelector)
                    .onSubmit {
                        if vm.intercurrency {
                            focusedField = .amountToSelector
                        } else {
                            focusedField = .note
                        }
                    }
                    .overlay(alignment: .trailing) {
                        Text(vm.currentTransaction.accountFrom.currency.symbol)
                    }

                }
                if vm.intercurrency || vm.currentTransaction.type == .balancing {
                    TextField(
                        "Сумма начисления",
                        value: $vm.amountTo,
                        formatter: NumberFormatters.textField
                    )
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amountToSelector)
                    .onSubmit {
                        focusedField = .note
                    }
                    .overlay(alignment: .trailing) {
                        Text(vm.currentTransaction.accountTo.currency.symbol)
                    }
                }
            } footer: {
                VStack {
                    HStack {
                        if vm.currentTransaction.accountFrom.currency != vm.accountGroup.currency {
                            Text("В валюте группы счетов: " + CurrencyFormatter().string(
                                number: vm.currentTransaction.amountFrom * (vm.accountGroup.currency.rate / vm.currentTransaction.accountFrom.currency.rate),
                                currency: vm.accountGroup.currency,
                                withUnits: false
                            ))
                        }
                        Spacer()
                    }
                    HStack {
                        if vm.intercurrency && vm.currentTransaction.type != .balancing {
                            Rate(vm.currentTransaction)
                        }
                        Spacer()
                    }
                }
            }
            Section {
                TextField("Заметка", text: $vm.currentTransaction.note, axis: .vertical)
                    .focused($focusedField, equals: .note)
            }
            Section(footer:
                Button {
                    withAnimation {
                        vm.shouldShowAdditionalSettings.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName:"chevron.down")
                            .rotationEffect(.degrees(vm.shouldShowAdditionalSettings ? 180 : 0))
                        Text("\(vm.shouldShowAdditionalSettings ? "Скрыть" : "Показать") дополнительные настройки")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
            ) {}
            if vm.shouldShowAdditionalSettings {
                Section {
                    Toggle("Учитывать транзакцию в графиках", isOn: $vm.currentTransaction.accountingInCharts)
                }
            }
            Section {
                CarouselDatePicker(selectedDate: $vm.currentTransaction.dateTransaction)
                    .onChange(of: vm.currentTransaction.dateTransaction) { _, _ in
                        Task {
                            do {
                                try await vm.save()
                            } catch {
                                alert(error)
                                return
                            }
                            
                            dismiss()
                        }
                    }
            }
            if vm.mode == .update {
                Section {
                    Button {
                        Task {
                            do {
                                try await vm.save()
                            } catch {
                                alert(error)
                                return
                            }
                            
                            dismiss()
                        }
                    } label: {
                        if vm.shouldShowProgress {
                            ProgressView()
                        } else {
                            Text("Сохранить")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                Section(footer:
                    VStack(alignment: .leading) {
                        Text("ID: \(vm.currentTransaction.id)")
                        Text("Дата и время создания: \(vm.currentTransaction.datetimeCreate, format: .dateTime)")
                    }
                ) {}
            }
			
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    
                    // Если (выбранное поле = поле ввода суммы списания) И (счет списания имеет ненулевой баланс) И (тип транзакции расход ИЛИ перевод)
                    if focusedField == .amountFromSelector && vm.currentTransaction.accountFrom.remainder != 0 && (vm.currentTransaction.type == .consumption || vm.currentTransaction.type == .transfer)  {
                        
                        // Кнопка ввода всего возможного баланса в поле ввода суммы списания
                        Button("Весь баланс: " + CurrencyFormatter().string(
                                        number: vm.currentTransaction.accountFrom.remainder,
                                        currency: vm.currentTransaction.accountFrom.currency
                                    )
                        ) {
                            
                            // Присваиваем сумме списания весь баланс счета списания
                            vm.amountFrom = vm.currentTransaction.accountFrom.remainder.doubleValue
                            
                            // Если транзакция между счетами в разной валюте
                            if vm.intercurrency {
                                
                                // После нажатия переходим к полю ввода суммы пополнения
                                focusedField = .amountToSelector
                            } else {
                                
                                // После нажатия переходим к полю ввода заметки
                                focusedField = .note
                            }
                        }
                    }
                    Spacer()
                    
                    // Кнопка Следующее поле / Сохранить над клавиатурой
                    Button(focusedField == .note ? "Готово" : "Следующее поле") {
                        
                        // Конфигурируем логику нажатия на кнопку на клавиатуре в зависимости от поля, на котором сейчас стоим
                        switch focusedField {
                        case  .amountFromSelector: // Поле ввода суммы списания
                            
                            // Если транзакция между счетами с разными валютами
                            if vm.intercurrency {
                                
                                // Переходим к полю ввода суммы пополнения
                                focusedField = .amountToSelector
                            } else {
                                
                                // Переходим к полю заметки
                                focusedField = .note
                            }
                        case .amountToSelector: // Поле выбора суммы пополнения
                            
                            // Переходим к полю ввода заметки
                            focusedField = .note
                            
                        case .note: // Поле ввода заметки
                            focusedField = nil
                        default:
                            focusedField = nil
                        }
                    }
                }
            }
        }
        .task {
            if vm.mode == .create {
                if vm.currentTransaction.accountFrom.id == 0 {
                    vm.shouldShowPickerAccountFrom = true
                } else {
                    focusedField = .amountFromSelector
                }
            }
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
        .disabled(vm.shouldDisableUI)
    }
}

#Preview {
    EditTransaction(
        transactionType: .consumption,
        accountGroup: AccountGroup(id: 4)
    )
    .environment(AlertManager(handle: {_ in }))
}

private struct Rate: View {
    
    private var rate: Decimal
    private var symbols: String
    
    init(_ transaction: Transaction) {
        guard transaction.amountFrom != 0 && transaction.amountTo != 0 else {
            rate = 0
            symbols = "\(transaction.accountFrom.currency.symbol)/\(transaction.accountTo.currency.symbol)"
            return
        }
        
        if transaction.amountFrom > transaction.amountTo {
            rate = transaction.amountFrom / transaction.amountTo
            symbols = "\(transaction.accountFrom.currency.symbol)/\(transaction.accountTo.currency.symbol)"
        } else {
            rate = transaction.amountTo / transaction.amountFrom
            symbols = "\(transaction.accountTo.currency.symbol)/\(transaction.accountFrom.currency.symbol)"
        }
    }
    
    private var currencyFormatter = CurrencyFormatter()
    
    var body: some View {
        Text("Курс: \(currencyFormatter.string(number: rate, suffix: symbols))")
    }
}

enum Position {
    case up, down
}

func getAccountsForShowingInCreate(accounts: [Account], position: Position, transactionType: TransactionType, excludedAccount: Account?) -> [Account] {
    var subfiltered = accounts.filter { $0.visible && $0.id != excludedAccount?.id ?? 0 }
    
    switch transactionType {
    case .consumption:
        switch position {
        case .up:
            subfiltered = subfiltered.filter { $0.type == .regular || $0.type == .debt }
        case .down:
            subfiltered = subfiltered.filter { $0.type == .expense }
        }
    case .transfer:
        subfiltered = subfiltered.filter { $0.type == .regular || $0.type == .debt }
    case .income:
        switch position {
        case .up:
            subfiltered = subfiltered.filter { $0.type == .earnings }
        case .down:
            subfiltered = subfiltered.filter { $0.type == .regular || $0.type == .debt }
        }
    default:
        subfiltered = []
    }
    return Account.groupAccounts(subfiltered.sorted(by: { $1.serialNumber > $0.serialNumber }))
}

private struct Pickers: View {
    
    
    @Binding var isPickerShowing: Bool
    var buttonName: String
    @State var parentAccount = Account()
    @Binding var account: Account
    var accounts: [Account]
    var position: Position
    var transactionType: TransactionType
    var excludeAccount: Account?
    @State var openSecondPicker: Bool = false
    
    var accountsToShow: [Account] {
        getAccountsForShowingInCreate(accounts: accounts, position: position, transactionType: transactionType, excludedAccount: excludeAccount)
    }
    
    var body: some View {
        Group {
            Button {
                withAnimation {
                    isPickerShowing.toggle()
                }
            } label: {
                Text(buttonName)
                Spacer()
                Text(account.name)
                    .foregroundStyle(.secondary)
                Text(account.currency.symbol)
                    .foregroundColor(.secondary)
            }
            if isPickerShowing {
                HStack {
                    Picker("", selection: $parentAccount) {
                        Text("Не выбрано")
                            .tag(Account())
                        ForEach (accountsToShow) { account in
                            HStack {
                                Text(account.name)
                            }
                            .tag(account)
                        }
                    }
                    .onChange(of: parentAccount) { _, newValue in
                        if !newValue.isParent {
                            account = parentAccount
                            withAnimation {
                                openSecondPicker = false
                            }
                        } else {
                            if newValue.childrenAccounts.count == 1 {
                                account = newValue.childrenAccounts[0]
                            } else {
                                withAnimation {
                                    openSecondPicker = true
                                }
                            }
                        }
                    }
                    if openSecondPicker {
                        Picker("", selection: $account) {
                            Text("Не выбрано")
                                .tag(Account())
                            ForEach (parentAccount.childrenAccounts) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text(account.currency.symbol)
                                        .foregroundColor(.secondary)
                                }
                                .tag(account)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
