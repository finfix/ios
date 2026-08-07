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
    var onDone: () -> Void

    @State private var rawInput: String = ""
    @State private var cursorPosition: Int = 0
    @State private var didSeedFromBinding = false

    private var hasOperator: Bool {
        CalculatorOperator.allCases.contains { rawInput.contains($0.rawValue) }
    }

    private var evaluatedValue: Double? {
        guard hasOperator else {
            return Double(rawInput.replacingOccurrences(of: ",", with: "."))
        }
        var expressionString = rawInput
        for op in CalculatorOperator.allCases {
            expressionString = expressionString.replacingOccurrences(of: op.rawValue, with: op.expressionSymbol)
        }
        // Отбрасываем висящий оператор на конце (например "100+")
        while let last = expressionString.last, "+-*/".contains(last) {
            expressionString.removeLast()
        }
        guard !expressionString.isEmpty else { return nil }
        let expression = NSExpression(format: expressionString)
        guard let result = expression.expressionValue(with: nil, context: nil) as? NSNumber else { return nil }
        return result.doubleValue
    }

    private var resultFormattedText: String? {
        guard let evaluatedValue else { return nil }
        return NumberFormatters.textField.string(from: NSNumber(value: evaluatedValue))
    }

    var body: some View {
        HStack {
            if rawInput.isEmpty {
                Text(title)
                    .foregroundStyle(.secondary)
            } else if isFocused.wrappedValue {
                VStack(alignment: .leading, spacing: 2) {
                    if hasOperator {
                        CursorText(text: rawInput, cursorPosition: cursorPosition, font: .caption, color: .secondary)
                        Text(resultFormattedText ?? rawInput)
                            .font(.body.bold())
                    } else {
                        CursorText(text: rawInput, cursorPosition: cursorPosition, font: .body, color: .primary)
                    }
                }
            } else {
                Text(resultFormattedText ?? rawInput)
            }

            Spacer()

            if hasOperator, let resultFormattedText {
                Button {
                    UIPasteboard.general.string = resultFormattedText
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused.wrappedValue = true
        }
        .background(
            CalculatorInputBridge(
                isFocused: isFocused,
                allowsOperators: true,
                doneTitle: "Готово",
                onKey: handleKey
            )
        )
        .onAppear(perform: seedFromBindingIfNeeded)
        .onChange(of: text) { _, _ in
            seedFromBindingIfNeeded()
        }
    }

    private func seedFromBindingIfNeeded() {
        guard !didSeedFromBinding else { return }
        didSeedFromBinding = true
        if !text.isEmpty {
            rawInput = text
            cursorPosition = rawInput.count
        }
    }

    private func insert(_ string: String) {
        let index = rawInput.index(rawInput.startIndex, offsetBy: cursorPosition)
        rawInput.insert(contentsOf: string, at: index)
        cursorPosition += string.count
    }

    private func handleKey(_ key: CalculatorKey) {
        switch key {
        case .digit(let digit):
            insert(digit)
        case .decimalSeparator:
            insert(".")
        case .op(let op):
            insert(op.rawValue)
        case .backspace:
            guard cursorPosition > 0 else { return }
            let index = rawInput.index(rawInput.startIndex, offsetBy: cursorPosition - 1)
            rawInput.remove(at: index)
            cursorPosition -= 1
        case .moveCursorLeft:
            cursorPosition = max(0, cursorPosition - 1)
        case .moveCursorRight:
            cursorPosition = min(rawInput.count, cursorPosition + 1)
        case .done:
            isFocused.wrappedValue = false
            onDone()
        }
        pushValueToBinding()
    }

    private func pushValueToBinding() {
        guard let evaluatedValue else {
            text = ""
            return
        }
        text = NSDecimalNumber(value: evaluatedValue).stringValue
    }
}

/// Текст с видимым мигающим курсором в позиции `cursorPosition`.
private struct CursorText: View {

    var text: String
    var cursorPosition: Int
    var font: Font
    var color: Color

    @State private var isCursorVisible = true

    var body: some View {
        let chars = Array(text)
        let clamped = min(max(cursorPosition, 0), chars.count)
        let prefix = String(chars[0..<clamped])
        let suffix = String(chars[clamped...])

        return HStack(spacing: 0) {
            Text(prefix)
                .font(font)
                .foregroundStyle(color)
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 18)
                .opacity(isCursorVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isCursorVisible.toggle()
                    }
                }
            Text(suffix)
                .font(font)
                .foregroundStyle(color)
        }
    }
}
