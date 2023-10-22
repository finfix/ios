//
//  CurrencyFormatter.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

class CurrencyFormatter: NumberFormatter {
        
    init(currency: String? = nil) {
        super.init()
        self.numberStyle = .currency
        self.minimumFractionDigits = 2
        self.maximumFractionDigits = 2
        self.groupingSeparator = "."
        self.usesGroupingSeparator = true
        if let currency = currency {
            self.currencyCode = currency
            self.currencySymbol = CurrencySymbols[currency]
        }
    }
    
    func string(number: Double, currency: String? = nil) -> String {
        
        if let currency = currency {
            self.currencyCode = currency
            self.currencySymbol = CurrencySymbols[currency]
        }
        
        var num = number
        
        let sign = ((num < 0) ? "-" : "" );
        
        num = fabs(num)
        
        if (num < 1000000.0){
            return "\(sign)\(round(num)) \(self.currencySymbol ?? "")"
        }
        
        let exp:Int = Int(log10(num) / 6.0 )
        
        let units:[String] = ["k","M","G","T","P","E"]
        
        let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10
        
        return "\(sign)\(roundedNum)\(units[exp-1]) \(self.currencySymbol ?? "")"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
