//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditTransaction")

struct EditTransaction: View {
    
    @Environment (\.dismiss) private var dismiss
    @State private var vm: EditTransactionViewModel
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    
    init(_ transaction: Transaction) {
        vm = EditTransactionViewModel(
            currentTransaction: transaction,
            oldTransaction: transaction,
            accountGroup: transaction.accountFrom.accountGroup,
            mode: .update
        )
    }
    
    init(transactionType: TransactionType, accountGroup: AccountGroup) {
        vm = EditTransactionViewModel(
            currentTransaction: Transaction(
                type: transactionType
            ),
            accountGroup: accountGroup,
            mode: .create
        )
    }
    
    var body: some View {
        Form {
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
                            showErrorAlert("\(error)")
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
            if vm.currentTransaction.id != 0 {
                Section(footer: 
                    Text("ID: \(vm.currentTransaction.id)")
                ) {}
			}
        }
        .task {
            vm.load()
        }
		.disabled(shouldDisableUI)
    }
}

#Preview {
    EditTransaction(Transaction())
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
