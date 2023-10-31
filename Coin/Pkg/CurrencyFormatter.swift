//
//  CurrencyFormatter.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

class CurrencyFormatter: NumberFormatter {
    
    // Передано ли minimumFractionDigits в функцию
    var userMaximumFractionDigits = false
    
    // Возможные окончания числа
    let units: [String] = ["", "k","M","G","T","P","E"]
    
    init(currency: String? = nil, maximumFractionDigits: Int? = nil) {
        super.init()
        self.numberStyle = .currency
        if let digits = maximumFractionDigits {
            self.maximumFractionDigits = digits
            self.userMaximumFractionDigits = true
        }
        self.groupingSeparator = "."
        self.usesGroupingSeparator = true
        if let currency = currency {
            self.currencyCode = currency
            self.currencySymbol = CurrencySymbols[currency]
        }
    }
    
    func string(number: Decimal, currency: String? = nil) -> String {
        
        if let currency = currency {
            self.currencyCode = currency
            self.currencySymbol = CurrencySymbols[currency]
        }
        
        var num = number
        let doubleNum = num.doubleValue
        
        // Считаем разрядность от модуля числа
        var countOfNumbers = 0
        if num != 0 {
            countOfNumbers = Int(log10(fabs(doubleNum))) + 1
        }
        
        switch(true) {
            // Передано значение в форматтер при инициализации
        case self.userMaximumFractionDigits: break
            // Число без дробной части
        case doubleNum.truncatingRemainder(dividingBy: 1) == 0:
            self.maximumFractionDigits = 0
            // Число больше миллиона
        case countOfNumbers >= 7:
            // Количество символов кратно 3
            if countOfNumbers % 3 == 0 {
                self.maximumFractionDigits = 1
            } else {
                self.maximumFractionDigits = 0
            }
            // Число меньше миллиона и число с дробью
        default:
            self.maximumFractionDigits = 2
        }
        
        var cutFactor = 0
        switch(true) {
            
            // Число меньше миллиона
        case countOfNumbers < 7:
            cutFactor = 0
            
        case countOfNumbers % 3 == 2:
            // 123 456 789 -> 12 345M
            cutFactor = countOfNumbers - 5
            
        case countOfNumbers % 3 != 2:
            // 12 345 678 -> 1 234,6M
            cutFactor = countOfNumbers - 4
            
        default:
            cutFactor = 0
        }
        
        num /= pow(10, Int(cutFactor))
        
        var selectedUnit = 0
        // Число больше миллиона
        
        if countOfNumbers >= 7 {
            selectedUnit = countOfNumbers / 3 - 1
        }
        
        self.positiveSuffix = String("\(units[selectedUnit]) \(self.currencySymbol ?? "")")
        self.negativeSuffix = String("\(units[selectedUnit]) \(self.currencySymbol ?? "")")
                        
        return self.string(for: num)!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
    
    var stringValue: String {
        return NSDecimalNumber(decimal:self).stringValue
    }
}
