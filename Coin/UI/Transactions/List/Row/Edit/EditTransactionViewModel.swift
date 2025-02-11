//
//  EditTransactionViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation
import SwiftUI
import Factory

@Observable
class EditTransactionViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    // View states
    var shouldShowPickerAccountFrom = false
    var shouldShowPickerAccountTo = false
    var shouldShowAdditionalSettings = false
    
    // Data
    var accounts: [Account] = []
    var tags: [Tag] = []
    var currentTransaction = Transaction()
    
    var showRateString: String? {
        guard (currentTransaction.amountFrom != 0 && (currentTransaction.amountTo != 0 || suggestAmountToString != nil)) ||
               (currentTransaction.amountTo != 0 && (currentTransaction.amountFrom != 0 || suggestAmountFromString != nil)) else { return nil }
        guard intercurrency && currentTransaction.type != .balancing else { return nil }
                        
        let amountFrom = !currentTransaction.amountFrom.isZero ? currentTransaction.amountFrom : Decimal(string: cleanInput(suggestAmountFromString ?? "0")) ?? .zero
        let amountTo = !currentTransaction.amountTo.isZero ? currentTransaction.amountTo : Decimal(string: cleanInput(suggestAmountToString ?? "0")) ?? .zero
        
        if amountFrom > amountTo {
            let rate = amountFrom / amountTo
            let symbols = "\(currentTransaction.accountFrom.currency.symbol)/\(currentTransaction.accountTo.currency.symbol)"
            return CurrencyFormatter().string(number: rate, suffix: symbols)
        } else {
            let rate = amountTo / amountFrom
            let symbols = "\(currentTransaction.accountTo.currency.symbol)/\(currentTransaction.accountFrom.currency.symbol)"
            return CurrencyFormatter().string(number: rate, suffix: symbols)
        }
    }
    
    var suggestAmountFromString: String? = nil
    var amountFromString: String = "" {
        didSet {
            
            guard amountFromString != oldValue else { return }
            
            let formatter = CurrencyFormatter(maximumFractionDigits: 7, withUnits: false)
            
            // Чистим строку от лишних символов
            let _amountFrom = cleanInput(amountFromString)
            
            let newValueAmountFrom = Decimal(string: _amountFrom) ?? 0
                        
            guard newValueAmountFrom != currentTransaction.amountFrom else { return }
            
            currentTransaction.amountFrom = newValueAmountFrom
            
            // Делаем текстовое значение правильно форматированным числом
            amountFromString = currentTransaction.amountFrom.currencyString(formatter: formatter)
                        
            // Получаем новое значение для amountTo
            let suggestAmount = convert(
                amountFrom: currentTransaction.amountFrom,
                currencyRateFrom: currentTransaction.accountFrom.currency.rate,
                currencyRateTo: currentTransaction.accountTo.currency.rate
            )
            
            suggestAmountToString = suggestAmount > 0 ? suggestAmount.currencyString(
                formatter: formatter,
                maximumFractionDigits: 2
            ) : nil
        }
    }
    
    var suggestAmountToString: String? = nil
    var amountToString: String = "" {
        didSet {
            
            guard amountToString != oldValue else { return }
            
            let formatter = CurrencyFormatter(maximumFractionDigits: 7, withUnits: false)
            
            // Чистим строку от лишних символов
            let _amountTo = cleanInput(amountToString)
                        
            // Парсим очищенную строку в decimal
            let newValueAmountTo = Decimal(string: _amountTo) ?? 0
                    
            guard newValueAmountTo != currentTransaction.amountTo else { return }
            
            currentTransaction.amountTo = newValueAmountTo
            
            // Делаем текстовое значение правильно форматированным числом
            amountToString = currentTransaction.amountTo.currencyString(formatter: formatter)
                        
            // Получаем новое значение для amountFrom
            let suggestAmount =
            convert(
                amountFrom: currentTransaction.amountTo,
                currencyRateFrom: currentTransaction.accountTo.currency.rate,
                currencyRateTo: currentTransaction.accountFrom.currency.rate
            )
            
            suggestAmountFromString = suggestAmount > 0 ? suggestAmount.currencyString(
                formatter: formatter,
                maximumFractionDigits: 2
            ) : nil
        }
    }
    var oldTransaction = Transaction()
    var accountGroup = AccountGroup()
    var mode: mode
    
    var intercurrency: Bool {
        currentTransaction.accountFrom.currency != currentTransaction.accountTo.currency
    }
    
    init(
        currentTransaction: Transaction,
        oldTransaction: Transaction = Transaction(),
        accountGroup: AccountGroup,
        mode: mode
    ) {
        self.currentTransaction = currentTransaction
        self.oldTransaction = oldTransaction
        self.accountGroup = accountGroup
        self.mode = mode
        
        if currentTransaction.amountFrom != 0 && currentTransaction.amountTo != 0 {
            let formatter = CurrencyFormatter(withUnits: false)
            amountFromString = currentTransaction.amountFrom.currencyString(formatter: formatter)
            amountToString = currentTransaction.amountTo.currencyString(formatter: formatter)
        }
    }
            
    func load() async throws {
        accounts = try await service.getAccounts(accountGroups: [accountGroup])
        tags = try await service.getTags(accountGroup: accountGroup)
    }
    
    func save() async throws {
        
        if currentTransaction.amountFrom.isZero {
            currentTransaction.amountFrom = Decimal(string: cleanInput(suggestAmountFromString ?? "0")) ?? .zero
        }
        
        if currentTransaction.amountTo.isZero {
            currentTransaction.amountTo = Decimal(string: cleanInput(suggestAmountToString ?? "0")) ?? .zero
        }
        
        switch mode {
        case .create: try await service.createTransaction(currentTransaction)
        case .update: try await service.updateTransaction(newTransaction: currentTransaction, oldTransaction: oldTransaction)
        }
    }
    
    func deleteTransaction() async throws {
        try await service.deleteTransaction(currentTransaction)
    }
}

// Функция для очистки строки
func cleanInput(_ input: String) -> String {
    // Удаляем все пробелы
    var cleanedInput = input.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
    
    // Если есть десятичный разделитель (точка или запятая), оставляем только один
    cleanedInput = cleanedInput.replacingOccurrences(of: ",", with: ".")
    
    // Оставляем только цифры и одну точку (для десятичной части)
    let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
    cleanedInput = String(cleanedInput.unicodeScalars.filter { allowedCharacters.contains($0) })
    
    // Убираем все символы после первой точки, если точка уже была
    let components = cleanedInput.split(separator: ".")
    if components.count > 1 {
        cleanedInput = components[0] + "." + components[1]
    }
    
    return cleanedInput
}

extension Decimal {
    func currencyString(
        formatter: CurrencyFormatter,
        currency: Currency? = nil,
        maximumFractionDigits: Int? = nil
    ) -> String {
        return formatter.string(number: self, currency: currency, maximumFractionDigits: maximumFractionDigits)
    }
}

func convert(amountFrom: Decimal, currencyRateFrom: Decimal, currencyRateTo: Decimal) -> Decimal {
        
    let basePrice = amountFrom / currencyRateFrom
    return basePrice * currencyRateTo
}
