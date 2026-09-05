//
//  CalculatorField.swift
//  Coin
//

import SwiftUI

// MARK: - Безопасный вычислитель выражений (без NSExpression)
//
// NSExpression(format:) трактует "%" как спецификатор формата (как в printf), поэтому
// любой оставшийся в строке "%" мог как падать с крашем, так и давать неверный результат.
// Вместо этого разбираем выражение в собственное AST и вычисляем его сами, что позволяет
// как контролировать семантику процента (A+B% = A + A*B/100, A×B% = A×(B/100)),
// так и никогда не крашиться на промежуточных/некорректных состояниях ввода — просто
// возвращаем nil, если выражение нельзя посчитать.

enum CalcToken: Equatable {
    case number(Double)
    case plus, minus, multiply, divide, percent
    case leftParen, rightParen
}
