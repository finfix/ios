//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct UpdateTransaction: View {
    
    @Binding var isUpdateOpen: Bool
    @Environment(AppSettings.self) var appSettings
//    @Environment(ModelData.self) var modelData
    
//    var oldTransaction: Transaction
    var id: UInt32
//    @State var accountFrom: Account
//    @State var accountTo: Account
    @State var amountFrom: String
    @State var amountTo: String
//    @State var dateTransaction: Date
    @State var note: String
    
    init(isUpdateOpen: Binding<Bool>, transaction: Transaction) {
        self._isUpdateOpen = isUpdateOpen
//        self.oldTransaction = transaction
        self.id = transaction.id
//        self.accountFrom = modelData.accountsMap[transaction.accountFromID]!
//        self.accountTo = modelData.accountsMap[transaction.accountToID]!
        self.amountFrom = String(transaction.amountFrom)
        self.amountTo = String(transaction.amountTo)
//        self.dateTransaction = transaction.dateTransaction
        self.note = transaction.note
    }
    
//    var accountsFrom: [Account] {
//        modelData.accounts.filter {
//            switch oldTransaction.type {
//            case .consumption:
//                return $0.type != .expense && $0.type != .earnings && $0.visible
//            case .income:
//                return $0.type == .earnings && $0.visible
//            case .transfer:
//                return $0.type != .expense && $0.type != .earnings && $0.visible
//            default:
//                return true
//            }
//        }
//    }
//    
//    var accountsTo: [Account] {
//        modelData.accounts.filter {
//            switch oldTransaction.type {
//            case .consumption:
//                return $0.type == .expense && $0.visible
//            case .income:
//                return $0.type != .expense && $0.type != .earnings && $0.visible
//            case .transfer:
//                return $0.type != .expense && $0.type != .earnings && $0.visible && $0.id != accountFrom.id
//            default:
//                return true
//            }
//        }
//    }
    
    var body: some View {
        Form {
//            Picker("Cчет списания", selection: $accountFrom) {
//                ForEach (accountsFrom) {
//                    Text($0.name).tag($0 as Account?)
//                }
//            }
            TextField("Сумма списания", text: $amountFrom)
                .keyboardType(.decimalPad)
            TextField("Сумма зачисления", text: $amountTo)
                .keyboardType(.decimalPad)
//            DatePicker(selection: $dateTransaction, displayedComponents: .date) {
//                Text("Дата транзакции")
//            }
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
        Button("Сохранить") {
            isUpdateOpen = false
            updateTransaction()
        }
    }
    
    func updateTransaction() {
        
        var req = UpdateTransactionReq(id: id)
//        if oldTransaction.dateTransaction != dateTransaction {
//            req.dateTransaction = dateTransaction
//        }
//        if oldTransaction.note != note {
            req.note = note
//        }
//        if String(oldTransaction.amountFrom) != self.amountFrom {
            req.amountFrom = Double(self.amountFrom.replacingOccurrences(of: ",", with: "."))
//        }
//        if String(oldTransaction.amountTo) != self.amountTo {
            req.amountTo = Double(self.amountTo.replacingOccurrences(of: ",", with: "."))
//        }
        
        TransactionAPI().UpdateTransaction(req: req) { error in
            if let err = error {
                appSettings.showErrorAlert(error: err)
            }
        }
    }
}

#Preview {
    UpdateTransaction(isUpdateOpen: .constant(true), transaction: Transaction(
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
