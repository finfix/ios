//
//  CalculatorInputBridge.swift
//  Coin
//

import SwiftUI
import UIKit

/// Настоящий (видимый) `UITextField`, который показывает вводимое выражение и вместо системной
/// клавиатуры подставляет через `inputView` нашу кастомную клавиатуру-калькулятор.
/// Благодаря тому, что это обычный `UITextField`, бесплатно работают выделение текста, лупа,
/// системное меню «Копировать/Вставить/Выбрать всё» и обычный (нативный) курсор.
struct CalculatorInputBridge: UIViewRepresentable {

    @Binding var text: String
    @Binding var isFocused: Bool
    var allowsOperators: Bool
    var doneTitle: String
    var placeholder: String
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var onDone: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.delegate = context.coordinator
        field.font = font
        field.textColor = textColor
        field.backgroundColor = .clear
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.text = text
        field.placeholder = placeholder
        field.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingChanged), for: .editingChanged)

        let hosting = context.coordinator.hostingController
        let height: CGFloat = allowsOperators ? 344 : 284
        hosting.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
        hosting.view.backgroundColor = .clear
        hosting.view.autoresizingMask = [.flexibleWidth]
        field.inputView = hosting.view

        context.coordinator.textField = field
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.onDone = onDone
        context.coordinator.hostingController.rootView = CalculatorKeypad(
            allowsOperators: allowsOperators,
            doneTitle: doneTitle,
            onKey: context.coordinator.handle
        )

        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }
        if uiView.font != font {
            uiView.font = font
        }
        if uiView.textColor != textColor {
            uiView.textColor = textColor
        }

        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool
        var onDone: () -> Void = {}
        weak var textField: UITextField?
        let hostingController = UIHostingController(
            rootView: CalculatorKeypad(allowsOperators: true, doneTitle: "Готово", onKey: { _ in })
        )

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
        }

        @objc func textFieldEditingChanged() {
            text = textField?.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !isFocused { isFocused = true }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if isFocused { isFocused = false }
        }

        func handle(_ key: CalculatorKey) {
            guard let field = textField else { return }
            switch key {
            case .digit(let digit):
                insert(digit, into: field)
            case .decimalSeparator:
                insert(".", into: field)
            case .op(let op):
                insert(op.rawValue, into: field)
            case .leftParen:
                insert("(", into: field)
            case .rightParen:
                insert(")", into: field)
            case .percent:
                insert("%", into: field)
            case .backspace:
                deleteBackward(field)
            case .clearAll:
                field.text = ""
                textFieldEditingChanged()
            case .moveCursorLeft:
                moveCursor(field, by: -1)
            case .moveCursorRight:
                moveCursor(field, by: 1)
            case .done:
                isFocused = false
                onDone()
            }
        }

        private func insert(_ string: String, into field: UITextField) {
            let range = field.selectedTextRange ?? field.textRange(from: field.endOfDocument, to: field.endOfDocument)!
            field.replace(range, withText: string)
            textFieldEditingChanged()
        }

        private func deleteBackward(_ field: UITextField) {
            guard let range = field.selectedTextRange else { return }
            if !range.isEmpty {
                field.replace(range, withText: "")
            } else if let newStart = field.position(from: range.start, offset: -1) {
                let deleteRange = field.textRange(from: newStart, to: range.start)!
                field.replace(deleteRange, withText: "")
            }
            textFieldEditingChanged()
        }

        private func moveCursor(_ field: UITextField, by offset: Int) {
            guard let range = field.selectedTextRange else { return }
            let newPosition = field.position(from: range.start, offset: offset)
                ?? (offset < 0 ? field.beginningOfDocument : field.endOfDocument)
            field.selectedTextRange = field.textRange(from: newPosition, to: newPosition)
        }
    }
}
