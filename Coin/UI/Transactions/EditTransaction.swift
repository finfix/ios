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
    
    @Environment (\.dismiss) private var dismiss
    @State private var vm: EditTransactionViewModel
    @Environment (AlertManager.self) private var alert
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
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
                        buttonName: "Счет списания",
                        account: $vm.currentTransaction.accountFrom,
                        accounts: vm.accounts,
                        position: .up,
                        transactionType: vm.currentTransaction.type
                    )
                    Pickers(
                        buttonName: "Счет пополнения",
                        account: $vm.currentTransaction.accountTo,
                        accounts: vm.accounts,
                        position: .down,
                        transactionType: vm.currentTransaction.type,
                        excludeAccount: vm.currentTransaction.accountFrom
                    )
                }
                .pickerStyle(.wheel)
            }
            Section {
                if vm.currentTransaction.type != .balancing {
                    TextField(vm.intercurrency ? "Сумма списания" : "Сумма", value: $vm.currentTransaction.amountFrom, format: .number)
                        .keyboardType(.decimalPad)
                }
                if vm.intercurrency || vm.currentTransaction.type == .balancing {
                    TextField("Сумма начисления", value: $vm.currentTransaction.amountTo, format: .number)
                        .keyboardType(.decimalPad)
                }
            } footer: {
                if vm.intercurrency && vm.currentTransaction.type != .balancing {
                    Rate(vm.currentTransaction)
                }
            }
            Section {
                DatePicker(selection: $vm.currentTransaction.dateTransaction, displayedComponents: .date) {
                    Text("Дата транзакции")
                }
            }
            Section {
                TextField("Заметка", text: $vm.currentTransaction.note, axis: .vertical)
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
                            case .create: try await vm.createTransaction()
                            case .update: try await vm.updateTransaction()
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
            
            Section(footer:
                VStack(alignment: .leading) {
                    Text("ID: \(vm.currentTransaction.id)")
                    Text("Дата и время создания: \(vm.currentTransaction.datetimeCreate, format: .dateTime)")
                }
            ) {}
			
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
		.disabled(shouldDisableUI)
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
    var subfiltered = accounts.filter { $0.visible && $0.id != excludedAccount?.id ?? 0 && !$0.isParent }
    
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
    return subfiltered.sorted(by: { $1.serialNumber > $0.serialNumber })
}

private struct Pickers: View {
    
    
    @State private var isPickerShowing = false
    var buttonName: String
    @Binding var account: Account
    var accounts: [Account]
    var position: Position
    var transactionType: TransactionType
    var excludeAccount: Account?
    
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
                Picker("", selection: $account) {
                    ForEach (accountsToShow) { account in
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
        .buttonStyle(.plain)
    }
}
