//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct UpdateTransaction: View {
    
    var oldTransaction: Transaction
    @State var transaction: Transaction
    
    init(_ transaction: Transaction) {
        self.oldTransaction = transaction
        _transaction = .init(wrappedValue: transaction)
    }
    @Environment (\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                TextField("Сумма списания", value: $transaction.amountFrom, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Сумма зачисления", value: $transaction.amountTo, format: .number)
                    .keyboardType(.decimalPad)
            }
            Section {
                TextField("Заметка", text: $transaction.note, axis: .vertical)
            }
            Section {
                Button("Сохранить") {
                    dismiss()
//                    updateTransaction()
                }
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
    UpdateTransaction(Transaction())
}
