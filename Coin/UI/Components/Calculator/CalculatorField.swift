//
//  CalculatorField.swift
//  Coin
//

import SwiftUI

/// Поле ввода суммы со своей клавиатурой-калькулятором.
/// Пока введены только цифры — работает как обычное числовое поле.
/// Как только появляется арифметический знак, поле показывает выражение (пока в фокусе)
/// и вычисленный результат (жирным, с кнопкой копирования). При потере фокуса выражение
/// скрывается, остаётся только результат.
struct CalculatorField: View {

    var title: String
    @Binding var text: String
    var isFocused: Binding<Bool>
    var allowsOperators: Bool
    var onDone: () -> Void

    @State private var rawInput: String = ""
    @State private var didSeedFromBinding = false
    @State private var lastValidValue: Double? = nil

    init(
        title: String,
        text: Binding<String>,
        isFocused: Binding<Bool>,
        allowsOperators: Bool = true,
        onDone: @escaping () -> Void = {}
    ) {
        self.title = title
        self._text = text
        self.isFocused = isFocused
        self.allowsOperators = allowsOperators
        self.onDone = onDone
    }

    /// Удобный инициализатор для полей, хранящих значение как `Double` (баланс, бюджет и т.п.).
    init(
        title: String,
        value: Binding<Double>,
        isFocused: Binding<Bool>,
        allowsOperators: Bool = true,
        onDone: @escaping () -> Void = {}
    ) {
        self.init(
            title: title,
            text: Binding<String>(
                get: { value.wrappedValue == 0 ? "" : NSDecimalNumber(value: value.wrappedValue).stringValue },
                set: { newValue in value.wrappedValue = Double(newValue) ?? 0 }
            ),
            isFocused: isFocused,
            allowsOperators: allowsOperators,
            onDone: onDone
        )
    }

    private var hasOperator: Bool {
        // ASCII "*"/"/" учитываем на случай вставленного (например, скопированного откуда-то) выражения.
        rawInput.contains { "+-*/×÷()%".contains($0) }
    }

    private var evaluatedValue: Double? {
        guard hasOperator else {
            return Double(rawInput.replacingOccurrences(of: ",", with: "."))
        }
        var expressionString = rawInput
        for op in CalculatorOperator.allCases {
            expressionString = expressionString.replacingOccurrences(of: op.rawValue, with: op.expressionSymbol)
        }
        return evaluateExpression(expressionString)
    }

    /// Показываем результат последнего успешного вычисления, если текущее выражение
    /// сейчас невалидно (например, деление на ноль или "9//*9").
    private var displayValue: Double? {
        evaluatedValue ?? lastValidValue
    }

    private var resultFormattedText: String? {
        guard let displayValue else { return nil }
        return NumberFormatters.textField.string(from: NSNumber(value: displayValue))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if isFocused.wrappedValue {
                    CalculatorInputBridge(
                        text: $rawInput,
                        isFocused: isFocused,
                        allowsOperators: allowsOperators,
                        doneTitle: "Готово",
                        placeholder: title,
                        font: hasOperator ? .preferredFont(forTextStyle: .caption1) : .preferredFont(forTextStyle: .body),
                        textColor: hasOperator ? .secondaryLabel : .label,
                        onDone: onDone
                    )
                    .frame(height: hasOperator ? 16 : 24)
                    if hasOperator {
                        Text(resultFormattedText ?? "0")
                            .font(.body.bold())
                            .foregroundStyle(resultFormattedText == nil ? .secondary : .primary)
                    }
                } else if rawInput.isEmpty {
                    Text(title)
                        .foregroundStyle(.secondary)
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused.wrappedValue = true }
                } else {
                    Text(resultFormattedText ?? "0")
                        .foregroundStyle(resultFormattedText == nil ? .secondary : .primary)
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused.wrappedValue = true }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear(perform: seedFromBindingIfNeeded)
        .onChange(of: text) { _, _ in
            seedFromBindingIfNeeded()
        }
        .onChange(of: rawInput) { _, _ in
            pushValueToBinding()
        }
    }

    private func seedFromBindingIfNeeded() {
        guard !didSeedFromBinding else { return }
        didSeedFromBinding = true
        if !text.isEmpty {
            rawInput = text
        }
    }

    private func pushValueToBinding() {
        guard let evaluatedValue else {
            // Текущее выражение невалидно (например "9//*9" или "100/0") — не трогаем
            // ни сохранённое значение, ни последний успешный результат, только когда
            // поле полностью очищено сбрасываем всё.
            if rawInput.isEmpty {
                lastValidValue = nil
                text = ""
            }
            return
        }
        lastValidValue = evaluatedValue
        text = NSDecimalNumber(value: evaluatedValue).stringValue
    }
}

// MARK: - Безопасный вычислитель выражений (без NSExpression)
//
// NSExpression(format:) трактует "%" как спецификатор формата (как в printf), поэтому
// любой оставшийся в строке "%" мог как падать с крашем, так и давать неверный результат.
// Вместо этого разбираем выражение в собственное AST и вычисляем его сами, что позволяет
// как контролировать семантику процента (A+B% = A + A*B/100, A×B% = A×(B/100)),
// так и никогда не крашиться на промежуточных/некорректных состояниях ввода — просто
// возвращаем nil, если выражение нельзя посчитать.

private enum CalcToken: Equatable {
    case number(Double)
    case plus, minus, multiply, divide, percent
    case leftParen, rightParen
}

private indirect enum CalcNode {
    case number(Double)
    case percent(CalcNode)
    case binary(CalcBinOp, CalcNode, CalcNode)
}

private enum CalcBinOp {
    case add, subtract, multiply, divide
}

private func calcTokenize(_ input: String) -> [CalcToken]? {
    var tokens: [CalcToken] = []
    let chars = Array(input)
    var i = 0
    while i < chars.count {
        let char = chars[i]
        switch char {
        case "+": tokens.append(.plus); i += 1
        case "-": tokens.append(.minus); i += 1
        case "*": tokens.append(.multiply); i += 1
        case "/": tokens.append(.divide); i += 1
        case "%": tokens.append(.percent); i += 1
        case "(": tokens.append(.leftParen); i += 1
        case ")": tokens.append(.rightParen); i += 1
        default:
            guard char.isNumber || char == "." else { return nil }
            var numberString = ""
            while i < chars.count, chars[i].isNumber || chars[i] == "." {
                numberString.append(chars[i])
                i += 1
            }
            guard let value = Double(numberString) else { return nil }
            tokens.append(.number(value))
        }
    }
    return tokens
}

private final class CalcParser {
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

/// `A+B%`/`A-B%` — процент от A (как умножение на 1±B/100).
/// `A*B%`/`A/B%` — B% как коэффициент (B/100).
private func calcEvaluate(_ node: CalcNode) -> Double? {
    switch node {
    case .number(let value):
        return value
    case .percent(let inner):
        guard let value = calcEvaluate(inner) else { return nil }
        return value / 100
    case .binary(let op, let leftNode, let rightNode):
        switch op {
        case .add:
            guard let left = calcEvaluate(leftNode) else { return nil }
            if case .percent(let percentInner) = rightNode {
                guard let percent = calcEvaluate(percentInner) else { return nil }
                return left + left * (percent / 100)
            }
            guard let right = calcEvaluate(rightNode) else { return nil }
            return left + right
        case .subtract:
            guard let left = calcEvaluate(leftNode) else { return nil }
            if case .percent(let percentInner) = rightNode {
                guard let percent = calcEvaluate(percentInner) else { return nil }
                return left - left * (percent / 100)
            }
            guard let right = calcEvaluate(rightNode) else { return nil }
            return left - right
        case .multiply:
            guard let left = calcEvaluate(leftNode), let right = calcEvaluate(rightNode) else { return nil }
            return left * right
        case .divide:
            guard let left = calcEvaluate(leftNode), let right = calcEvaluate(rightNode), right != 0 else { return nil }
            return left / right
        }
    }
}

private func evaluateExpression(_ input: String) -> Double? {
    var expressionString = input

    // Отбрасываем висящий оператор или незакрытую скобку на конце (например "100+" или "(2+3+")
    while let last = expressionString.last, "+-*/(".contains(last) {
        expressionString.removeLast()
    }
    guard !expressionString.isEmpty else { return nil }

    // Автоматически закрываем незакрытые скобки, пока пользователь ещё печатает
    var depth = 0
    for char in expressionString {
        if char == "(" {
            depth += 1
        } else if char == ")" {
            depth -= 1
            guard depth >= 0 else { return nil }
        }
    }
    if depth > 0 {
        expressionString += String(repeating: ")", count: depth)
    }

    guard let tokens = calcTokenize(expressionString),
          let ast = CalcParser(tokens).parseAll()
    else { return nil }
    return calcEvaluate(ast)
}
