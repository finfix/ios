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
    
    init(isUpdateOpen: Binding<Bool>, transaction: Transaction) {
        self._isUpdateOpen = isUpdateOpen
        self.id = transaction.id
        self.amountFrom = transaction.amountFrom.stringValue
        self.amountTo = transaction.amountTo.stringValue
        self.note = transaction.note
    }
    @Environment (\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                TextField("Сумма списания", text: $amountFrom)
                    .keyboardType(.decimalPad)
                TextField("Сумма зачисления", text: $amountTo)
                    .keyboardType(.decimalPad)
                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Заметка")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    TextEditor(text: $note)
                        .lineLimit(5)
                }
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
    UpdateTransaction(transaction: Transaction(
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
