//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct UpdateTransaction: View {
    
    
    var id: UInt32
    @State var amountFrom: String
    @State var amountTo: String
    @State var note: String
    @State var date: Date
    @State var accountFromID: UInt32
    @State var accountToID: UInt32
    
    init(_ transaction: Transaction) {
        self.id = transaction.id
        _amountFrom = .init(wrappedValue: transaction.amountFrom.stringValue)
        _amountTo = .init(wrappedValue: transaction.amountTo.stringValue)
        _note = .init(wrappedValue: transaction.note)
        _date = .init(wrappedValue: transaction.dateTransaction)
        _accountFromID = .init(wrappedValue: transaction.accountFromID)
        _accountToID = .init(wrappedValue: transaction.accountToID)
    }
    @Environment (\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                TextField("Сумма списания", text: $amountFrom)
                    .keyboardType(.decimalPad)
                TextField("Сумма зачисления", text: $amountTo)
                    .keyboardType(.decimalPad)
            }
            Section {
                TextField("Заметка", text: $note, axis: .vertical)
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
            do {
                var req = UpdateTransactionReq(id: id)
                req.note = note
                req.amountFrom = Double(self.amountFrom.replacingOccurrences(of: ",", with: "."))
                req.amountTo = Double(self.amountTo.replacingOccurrences(of: ",", with: "."))
                try await TransactionAPI().UpdateTransaction(req: req)
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    UpdateTransaction(Transaction(
        accountFromID: 1,
        accountToID: 2,
        accounting: true,
        amountFrom: 30,
        amountTo: 50,
        dateTransaction: Date(),
        id: 1,
        isExecuted: true,
        note: "Заметка",
        type: .transfer))
}
