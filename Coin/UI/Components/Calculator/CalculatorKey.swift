//
//  CalculatorKeypad.swift
//  Coin
//

import SwiftUI

enum CalculatorKey: Hashable {
    case digit(String)
    case decimalSeparator
    case op(CalculatorOperator)
    case leftParen
    case rightParen
    case percent
    case backspace
    case clearAll
    case moveCursorLeft
    case moveCursorRight
    case done
    case insertBalance
}
