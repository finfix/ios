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
    @Environment(\.modelContext) private var modelContext
    private var oldTransaction: Transaction = Transaction()
    @Bindable private var transaction: Transaction
    @Query private var accounts: [Account]
    @Query private var accountGroups: [AccountGroup]
    
    private var mode: Mode
    
    init(_ transaction: Transaction) {
        mode = .update
        self.oldTransaction = transaction
        _transaction = .init(wrappedValue: transaction)
    }
    
    init(transactionType: TransactionType) {
        mode = .create
        _transaction = .init(wrappedValue: Transaction(
                id: UInt32.random(in: 10000..<10000000),
                type: transactionType
            )
        )
    }
    
    @State private var accountGroupFrom = AccountGroup()
    @State private var accountGroupTo = AccountGroup()
    
    private var intercurrency: Bool {
        return transaction.accountFrom?.currency != transaction.accountTo?.currency
    }
    
    private var accountsFrom: [Account] {
        let subFiltered = accounts.filter {
            return $0.accountGroup == accountGroupFrom && $0.visible && $0.childrenAccounts.isEmpty
        }
        return subFiltered.filter {
            switch transaction.type {
            case .consumption:
                return $0.type != .expense && $0.type != .earnings
            case .income:
                return $0.type == .earnings
            case .transfer:
                return $0.type != .expense && $0.type != .earnings
            default:
                return true
            }
        }
    }
    
    private var accountsTo: [Account] {
        let subFiltered = accounts.filter {
                return $0.accountGroup == accountGroupTo && $0.visible && $0.childrenAccounts.isEmpty
        }
        return subFiltered.filter {
            switch transaction.type {
            case .consumption:
                return $0.type == .expense
            case .income:
                return $0.type != .expense && $0.type != .earnings
            case .transfer:
                return $0.type != .expense && $0.type != .earnings && $0 != transaction.accountFrom
            default:
                return true
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 0) {
                    Picker("", selection: $accountGroupFrom) {
                        ForEach (accountGroups) { accountGroup in
                            Text(accountGroup.name)
                                .tag(accountGroup)
                        }
                    }
                    Picker("", selection: $transaction.accountFrom) {
                        ForEach (accountsFrom) { account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(account.currency!.symbol)
                                    .foregroundColor(.secondary)
                            }
                            .tag(account as Account?)
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    Picker("", selection: $accountGroupTo) {
                        ForEach (accountGroups) { accountGroup in
                            Text(accountGroup.name)
                                .tag(accountGroup)
                        }
                    }
                    Picker("", selection: $transaction.accountTo) {
                        ForEach (accountsTo) { account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(account.currency?.symbol ?? "?")
                                    .foregroundColor(.secondary)
                            }
                            .tag(account as Account?)
                        }
                    }
                }
                
                TextField(intercurrency ? "Сумма списания" : "Сумма", value: $transaction.amountFrom, format: .number)
                    .keyboardType(.decimalPad)
                if intercurrency {
                    TextField("Сумма начисления", value: $transaction.amountTo, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                DatePicker(selection: $transaction.dateTransaction, displayedComponents: .date) {
                    Text("Дата транзакции")
                }
            }
            .pickerStyle(.wheel)
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
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        
        if !intercurrency {
            transaction.amountTo = transaction.amountFrom
        }
        
        
        
        Task {
            do {
                transaction.dateTransaction = transaction.dateTransaction.stripTime()
                let id = try await TransactionAPI().CreateTransaction(req: CreateTransactionReq(
                    accountFromID: transaction.accountFrom?.id ?? 0,
                    accountToID: transaction.accountTo?.id ?? 0,
                    amountFrom: transaction.amountFrom,
                    amountTo: transaction.amountTo,
                    dateTransaction: format.string(from: transaction.dateTransaction),
                    note: transaction.note,
                    type: transaction.type.rawValue,
                    isExecuted: true))
                
                    switch transaction.type {
                    case .income:
                        transaction.accountFrom!.remainder += transaction.amountFrom
                        transaction.accountTo!.remainder += transaction.amountTo
                    case .transfer, .consumption:
                        transaction.accountFrom!.remainder -= transaction.amountFrom
                        transaction.accountTo!.remainder += transaction.amountTo
                    default: break
                    }
                    
                    transaction.id = id
                    transaction.isSaved = true
                    try modelContext.save()
            } catch {
                modelContext.rollback()
                logger.error("\(error)")
            }
        }
    }
    
    func updateTransaction() {
        
        Task {
            do {
                try await TransactionAPI().UpdateTransaction(req: UpdateTransactionReq(
                    accountFromID: transaction.accountFrom?.id, 
                    accountToID: transaction.accountTo?.id, 
                    amountFrom: transaction.amountFrom,
                    amountTo: transaction.amountTo,
                    dateTransaction: transaction.dateTransaction,
                    note: transaction.note,
                    id: transaction.id))
                try modelContext.save()
            } catch {
                modelContext.rollback()
                logger.error("\(error)")
            }
        }
    }
}

#Preview {
    EditTransaction(Transaction())
        .modelContainer(previewContainer)
}

extension Date {

    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }

}
