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

struct EditTransaction: View {
    
    private enum Field: Hashable {
        case amountFromSelector, amountToSelector, note
    }
    @FocusState private var focusedField: Field?
    
    @Environment (\.dismiss) private var dismiss
    @State private var vm: EditTransactionViewModel
    @Environment (AlertManager.self) private var alert
    
    @Binding var path: NavigationPath
    
    init(_ transaction: Transaction, path: Binding<NavigationPath>) {
        vm = EditTransactionViewModel(
            currentTransaction: transaction,
            oldTransaction: transaction,
            accountGroup: transaction.accountFrom.accountGroup,
            mode: .update
        )
        self._path = path
    }
    
    init(transactionType: TransactionType, accountGroup: AccountGroup, path: Binding<NavigationPath>) {
        vm = EditTransactionViewModel(
            currentTransaction: Transaction(
                accountingInCharts: true, 
                type: transactionType
            ),
            accountGroup: accountGroup,
            mode: .create
        )
        self._path = path
    }
    
    var body: some View {
        Form {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            Button {
                                if vm.currentTransaction.tags.contains(tag) {
                                    vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                } else {
                                    vm.currentTransaction.tags.append(tag)
                                }
                            } label: {
                                ZStack {
                                    Text("#\(tag.name)")
                                        .padding(5)
                                        .overlay {
                                            if vm.currentTransaction.tags.contains(tag) {
                                                RoundedRectangle(cornerRadius: 5)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    
                                }
                            }
                        }
                    }
                }
                Button {
                    path.append(EditTransactionRoute.tagsList)
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            .buttonStyle(.plain)
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
                    TextField(vm.intercurrency ? "Сумма списания" : "Сумма", value: $vm.currentTransaction.amountFrom, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amountFromSelector)
                        .onSubmit {
                            if vm.intercurrency {
                                focusedField = .amountToSelector
                            } else {
                                vm.shouldShowDatePicker = true
                            }
                        }
                }
                if vm.intercurrency || vm.currentTransaction.type == .balancing {
                    TextField("Сумма начисления", value: $vm.currentTransaction.amountTo, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amountToSelector)
                        .onSubmit {
                            withAnimation {
                                vm.shouldShowDatePicker = true
                            }
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
                ExpandableDatePicker(
                    buttonName: "Дата",
                    isCalendarShowing: $vm.shouldShowDatePicker,
                    date: Binding<Date?>($vm.currentTransaction.dateTransaction),
                    showClearButton: false
                )
                .onChange (of: vm.currentTransaction.dateTransaction) { _, _ in
                    withAnimation {
                        vm.shouldShowDatePicker = false
                        focusedField = .note
                    }
                }
            }
            Section {
                TextField("Заметка", text: $vm.currentTransaction.note, axis: .vertical)
                    .focused($focusedField, equals: .note)
            }
            Section {
                Toggle("Учитывать транзакцию в графиках", isOn: $vm.currentTransaction.accountingInCharts)
            }
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    if focusedField == .amountFromSelector && (vm.currentTransaction.type == .consumption || vm.currentTransaction.type == .transfer )  {
                        Button("Весь баланс: " + CurrencyFormatter().string(
                                        number: vm.currentTransaction.accountFrom.remainder,
                                        currency: vm.currentTransaction.accountFrom.currency
                                    )
                        ) {
                            vm.currentTransaction.amountFrom = vm.currentTransaction.accountFrom.remainder
                        }
                    }
                    Spacer()
                    Button(focusedField == .note ? "Сохранить" : "Следующее поле") {
                        switch focusedField {
                        case  .amountFromSelector:
                            if vm.intercurrency {
                                focusedField = .amountToSelector
                            } else {
                                vm.shouldShowDatePicker = true
                                focusedField = nil
                            }
                        case .amountToSelector:
                            vm.shouldShowDatePicker = true
                            focusedField = nil
                        case .note:
                            focusedField = nil
                            Task {
                                do {
                                    try await vm.save()
                                } catch {
                                    alert(error)
                                    return
                                }
                                dismiss()
                            }
                        default:
                            focusedField = nil
                        }
                    }
                }
            }
        }
        .task {
            if vm.mode == .create {
                vm.shouldShowPickerAccountFrom = true
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
    EditTransaction(Transaction(), path: .constant(NavigationPath()))
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
