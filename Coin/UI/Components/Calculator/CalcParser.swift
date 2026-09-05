//
//  CalculatorField.swift
//  Coin
//

import SwiftUI

final class CalcParser {
    private let tokens: [CalcToken]
    private var position = 0

    init(_ tokens: [CalcToken]) {
        self.tokens = tokens
    }

    private var current: CalcToken? {
        position < tokens.count ? tokens[position] : nil
    }

    func parseAll() -> CalcNode? {
        guard let node = parseExpression(), position == tokens.count else { return nil }
        return node
    }

    private func parseExpression() -> CalcNode? {
        guard var left = parseTerm() else { return nil }
        while let token = current, token == .plus || token == .minus {
            position += 1
            guard let right = parseTerm() else { return nil }
            left = .binary(token == .plus ? .add : .subtract, left, right)
        }
        return left
    }

    private func parseTerm() -> CalcNode? {
        guard var left = parseFactorWithPercent() else { return nil }
        while let token = current, token == .multiply || token == .divide {
            position += 1
            guard let right = parseFactorWithPercent() else { return nil }
            left = .binary(token == .multiply ? .multiply : .divide, left, right)
        }
        return left
    }

    private func parseFactorWithPercent() -> CalcNode? {
        guard var node = parseFactor() else { return nil }
        while current == .percent {
            position += 1
            node = .percent(node)
        }
        return node
    }

    private func parseFactor() -> CalcNode? {
        guard let token = current else { return nil }
        switch token {
        case .number(let value):
            position += 1
            return .number(value)
        case .leftParen:
            position += 1
            guard let inner = parseExpression(), current == .rightParen else { return nil }
            position += 1
            return inner
        case .minus:
            position += 1
            guard let inner = parseFactor() else { return nil }
            return .binary(.subtract, .number(0), inner)
        default:
            return nil
        }
    }
}
