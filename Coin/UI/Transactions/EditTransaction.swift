//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditTransaction")

struct EditTransaction: View {
    
    private enum Mode {
    case create, update
    }
    
    @Environment (\.dismiss) private var dismiss
    private var modelContext: ModelContext
    private var oldTransaction: Transaction = Transaction()
    @Bindable private var transaction: Transaction
    private var accountGroups: [AccountGroup]
    
    private var mode: Mode
    
    init(_ transaction: Transaction) {
        self.init()
        mode = .update
        self.oldTransaction = transaction
        self.transaction = modelContext.model(for: transaction.persistentModelID) as! Transaction
    }
    
    init(transactionType: TransactionType) {
        self.init()
        mode = .create
        _transaction = .init(wrappedValue: Transaction(
            type: transactionType
        ))
    }
    
    private init() {
        modelContext = ModelContext(container)
        modelContext.autosaveEnabled = false
        accountGroups = try! modelContext.fetch(FetchDescriptor<AccountGroup>(sortBy: [SortDescriptor(\.serialNumber)]))
        transaction = Transaction()
        mode = .create
    }
    
    private var intercurrency: Bool {
        return transaction.accountFrom?.currency != transaction.accountTo?.currency
    }
    
    var body: some View {
        Form {
            Section {
                Pickers(
                    buttonName: "Счет списания",
                    account: $transaction.accountFrom,
                    accountGroups: accountGroups,
                    position: .up,
                    transactionType: transaction.type
                )
                Pickers(
                    buttonName: "Счет пополнения",
                    account: $transaction.accountTo,
                    accountGroups: accountGroups,
                    position: .down,
                    transactionType: transaction.type,
                    excludeAccount: transaction.accountFrom
                )
            }
            .pickerStyle(.wheel)
            Section {
                TextField(intercurrency ? "Сумма списания" : "Сумма", value: $transaction.amountFrom, format: .number)
                    .keyboardType(.decimalPad)
                if intercurrency {
                    TextField("Сумма начисления", value: $transaction.amountTo, format: .number)
                        .keyboardType(.decimalPad)
                }
            } footer: {
                if intercurrency {
                    Rate(transaction)
                }
            }
            Section {
                DatePicker(selection: $transaction.dateTransaction, displayedComponents: .date) {
                    Text("Дата транзакции")
                }
            }
            Section {
                TextField("Заметка", text: $transaction.note, axis: .vertical)
            }
            Section {
                Button("Сохранить") {
                    switch mode {
                    case .create: createTransaction()
                    case .update: updateTransaction()
                    }
                    dismiss()
                }
            }
        }
    }
    
    func createTransaction() {
        
        if !intercurrency {
            transaction.amountTo = transaction.amountFrom
        }
        
        Task {
            do {
                transaction.dateTransaction = transaction.dateTransaction.stripTime()
                transaction.id = try await TransactionAPI().CreateTransaction(req: CreateTransactionReq(
                    accountFromID: transaction.accountFrom?.id ?? 0,
                    accountToID: transaction.accountTo?.id ?? 0,
                    amountFrom: transaction.amountFrom,
                    amountTo: transaction.amountTo,
                    dateTransaction: transaction.dateTransaction,
                    note: transaction.note,
                    type: transaction.type.rawValue,
                    isExecuted: true
                ))
                modelContext.insert(transaction)
                switch transaction.type {
                case .income:
                    transaction.accountFrom!.remainder += transaction.amountFrom
                    transaction.accountTo!.remainder += transaction.amountTo
                case .transfer, .consumption:
                    transaction.accountFrom!.remainder -= transaction.amountFrom
                    transaction.accountTo!.remainder += transaction.amountTo
                default: break
                }
                try modelContext.save()
            } catch {
                showErrorAlert("\(error)")
                logger.error("\(error)")
            }
        }
    }
    
    func updateTransaction() {
        
        Task {
            do {
                transaction.dateTransaction = transaction.dateTransaction.stripTime()
                try await TransactionAPI().UpdateTransaction(req: UpdateTransactionReq(
                    accountFromID: transaction.accountFrom?.id != oldTransaction.accountFrom?.id ? transaction.accountFrom?.id : nil,
                    accountToID: transaction.accountTo?.id != oldTransaction.accountTo?.id ? transaction.accountTo?.id : nil,
                    amountFrom: transaction.amountFrom != oldTransaction.amountFrom ? transaction.amountFrom : nil,
                    amountTo: transaction.amountTo != oldTransaction.amountTo ? transaction.amountTo : nil,
                    dateTransaction: transaction.dateTransaction != oldTransaction.dateTransaction ? transaction.dateTransaction : nil,
                    note: transaction.note != oldTransaction.note ? transaction.note : nil,
                    id: transaction.id))
                try modelContext.save()
            } catch {
                showErrorAlert("\(error)")
                logger.error("\(error)")
            }
        }
    }
}

#Preview {
    EditTransaction(Transaction())
        .modelContainer(previewContainer)
}

private struct Rate: View {
    
    private var rate: Decimal
    private var symbols: String
    
    init(_ transaction: Transaction) {
        guard transaction.amountFrom != 0 && transaction.amountTo != 0 else {
            rate = 0
            symbols = "\(transaction.accountFrom?.currency?.symbol ?? "")/\(transaction.accountTo?.currency?.symbol ?? "")"
            return
        }

        if transaction.amountFrom > transaction.amountTo {
            rate = transaction.amountFrom / transaction.amountTo
            symbols = "\(transaction.accountFrom?.currency?.symbol ?? "")/\(transaction.accountTo?.currency?.symbol ?? "")"
        } else {
            rate = transaction.amountTo / transaction.amountFrom
            symbols = "\(transaction.accountTo?.currency?.symbol ?? "")/\(transaction.accountFrom?.currency?.symbol ?? "")"
        }
    }
    
    private var currencyFormatter = CurrencyFormatter()
    
    var body: some View {
        Text("Курс: \(currencyFormatter.string(number: rate, suffix: symbols))")
    }
}

extension Date {

    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }

}

private struct Pickers: View {
    
    enum Position {
        case up, down
    }
    
    @State private var isPickerShowing = false
    var buttonName: String
    @Binding var account: Account?
    var accountGroups: [AccountGroup]
    @State private var accountGroup = AccountGroup()
    var position: Position
    var transactionType: TransactionType
    var excludeAccount: Account?
    
    var accounts: [Account] {
        var subfiltered = accountGroup.accounts.filter { $0.visible && $0.id != excludeAccount?.id ?? 0 }
        
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
    
    var body: some View {
        Group {
            Button {
                withAnimation {
                    isPickerShowing.toggle()
                }
            } label: {
                Text(buttonName)
                Spacer()
                Text(account?.name ?? "Счет не выбран")
                    .foregroundStyle(.secondary)
                Text(account?.currency?.symbol ?? "?")
                    .foregroundColor(.secondary)
            }
            if isPickerShowing {
                HStack(spacing: 0) {
                    Picker("", selection: $accountGroup) {
                        ForEach (accountGroups) { accountGroup in
                            Text(accountGroup.name)
                                .tag(accountGroup)
                        }
                    }
                    .onChange(of: accountGroup) {
                        account = accountGroup.accounts.first
                    }
                    Picker("", selection: $account) {
                        ForEach (accounts) { account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(account.currency!.symbol)
                                    .foregroundColor(.secondary)
                                if account.parentAccountID != nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .tag(account as Account?)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let account {
                self.accountGroup = accountGroups.first { $0.accounts.contains(account) }!
                self.account = account
            } else {
                accountGroup = accountGroups.first ?? AccountGroup()
                self.account = accounts.first
            }
        }
        .buttonStyle(.plain)
    }
}
