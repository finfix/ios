//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import SwiftData

struct EditTransaction: View {
    
    private enum Mode {
    case create, update
    }
    
    @Environment (\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private var oldTransaction: Transaction = Transaction()
    @State private var transaction: Transaction
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
        (accountGroupFrom.accounts  ?? []).filter {
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
        (accountGroupTo.accounts ?? []).filter {
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
                                Text(account.currency?.symbol ?? "?")
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
                Button {
//                    createTransaction()
                    dismiss()
                } label: {
                    Text("Сохранить")
                }
                .padding()
            }
        }
    }
    
    func createTransaction() {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        
        if !intercurrency {
            transaction.amountTo = transaction.amountFrom
        }
        
        debugLog(transaction.accountFrom!.remainder)
        transaction.accountFrom!.remainder -= transaction.amountFrom
        debugLog(transaction.accountFrom!.remainder)
        
        Task {
            do {
                modelContext.insert(transaction)
                let id = try await TransactionAPI().CreateTransaction(req: CreateTransactionReq(
                    accountFromID: transaction.accountFrom?.id ?? 0,
                    accountToID: transaction.accountTo?.id ?? 0,
                    amountFrom: transaction.amountFrom,
                    amountTo: transaction.amountTo,
                    dateTransaction: format.string(from: transaction.dateTransaction),
                    note: transaction.note,
                    type: transaction.type.rawValue,
                    isExecuted: true))
                
                    transaction.id = id
            } catch {
                debugLog(error)
            }
        }
    }
    
    func updateTransaction() {
        
        Task {
            var req = UpdateTransactionReq(id: transaction.id)
            if oldTransaction.accountFrom != transaction.accountFrom {
                req.accountFromID = transaction.accountFrom?.id
            }
            if oldTransaction.accountTo != transaction.accountTo {
                req.accountToID = transaction.accountTo?.id
            }
            if oldTransaction.amountFrom != transaction.amountFrom {
                req.amountFrom = transaction.amountFrom
            }
            if oldTransaction.amountTo != transaction.amountTo {
                req.amountTo = transaction.amountTo
            }
            if oldTransaction.dateTransaction != transaction.dateTransaction {
                req.dateTransaction = transaction.dateTransaction
            }
            if oldTransaction.note != transaction.note {
                req.note = transaction.note
            }
            
            do {
                try await TransactionAPI().UpdateTransaction(req: req)
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    EditTransaction(Transaction())
        .modelContainer(previewContainer)
}
