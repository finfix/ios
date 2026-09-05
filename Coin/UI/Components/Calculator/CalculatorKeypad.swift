//
//  CalculatorKeypad.swift
//  Coin
//

import SwiftUI



struct CalculatorKeypad: View {

    var allowsOperators: Bool
    var doneTitle: String
    /// Кнопка "вставить текущий баланс счёта" в верхнем ряду, рядом со стрелками/Готово —
    /// nil, если для этого поля вставка баланса не имеет смысла (см. вызывающую сторону,
    /// например EditTransaction: разный счёт в фокусе — разная подпись/значение).
    var insertBalanceLabel: String? = nil
    var onKey: (CalculatorKey) -> Void

    private let extraRow: [String] = ["(", ")", "⌫"]

    private let digitRows: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        ["%", "0", "."]
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Button {
                    onKey(.moveCursorLeft)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Button {
                    onKey(.moveCursorRight)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Spacer()
                if let insertBalanceLabel {
                    Button(insertBalanceLabel) {
                        onKey(.insertBalance)
                    }
                    .font(.footnote)
                    .lineLimit(1)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    Spacer()
                }
                Button(doneTitle) {
                    onKey(.done)
                }
                .font(.body.bold())
                .frame(minWidth: 88, minHeight: 44)
                .contentShape(Rectangle())
            }
            .font(.body)
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.leading, 8)
            .padding(.trailing, 4)

            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 8) {
                    if allowsOperators {
                        HStack(spacing: 8) {
                            ForEach(extraRow, id: \.self) { symbol in
                                keyButton(for: symbol)
                            }
                        }
                    }
                    ForEach(digitRows, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(row, id: \.self) { symbol in
                                keyButton(for: symbol)
                            }
                        }
                    }
                }

                if allowsOperators {
                    VStack(spacing: 8) {
                        clearButton()
                        operatorButton(.divide)
                        operatorButton(.multiply)
                        operatorButton(.subtract)
                        operatorButton(.add)
                    }
                    .frame(width: 64)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .padding(.bottom, 24)
        .background(Color(UIColor.systemGray5))
    }

    @ViewBuilder
    private func keyButton(for symbol: String) -> some View {
        Button {
            switch symbol {
            case "⌫": onKey(.backspace)
            case ".": onKey(.decimalSeparator)
            case "(": onKey(.leftParen)
            case ")": onKey(.rightParen)
            case "%": onKey(.percent)
            default: onKey(.digit(symbol))
            }
        } label: {
            Group {
                if symbol == "⌫" {
                    Image(systemName: "delete.left")
                } else {
                    Text(symbol)
                }
            }
            .font(.title2)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(UIColor.systemBackground))
        .foregroundStyle(Color.primary)
        .cornerRadius(8)
    }

    @ViewBuilder
    private func clearButton() -> some View {
        Button {
            onKey(.clearAll)
        } label: {
            Text("AC")
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(UIColor.systemGray4))
        .foregroundStyle(Color.primary)
        .cornerRadius(8)
    }

    @ViewBuilder
    private func operatorButton(_ op: CalculatorOperator) -> some View {
        Button {
            onKey(.op(op))
        } label: {
            Text(op.rawValue)
                .font(.title2)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.accentColor)
        .foregroundStyle(Color.white)
        .cornerRadius(8)
    }
}

#Preview {
    CalculatorKeypad(allowsOperators: true, doneTitle: "Готово", onKey: { _ in })
}
