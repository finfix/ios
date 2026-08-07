//
//  CalculatorInputBridge.swift
//  Coin
//

import SwiftUI
import UIKit

/// Невидимый UITextField, который служит "якорем" фокуса и хостом для кастомной клавиатуры-калькулятора,
/// подставляемой через `inputView` вместо системной клавиатуры.
struct CalculatorInputBridge: UIViewRepresentable {

    @Binding var isFocused: Bool
    var allowsOperators: Bool
    var doneTitle: String
    var onKey: (CalculatorKey) -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.delegate = context.coordinator
        field.tintColor = .clear
        field.textColor = .clear
        field.backgroundColor = .clear
        field.autocorrectionType = .no
        field.isUserInteractionEnabled = false

        let hosting = context.coordinator.hostingController
        hosting.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 260)
        hosting.view.backgroundColor = .clear
        hosting.view.autoresizingMask = [.flexibleWidth]
        field.inputView = hosting.view

        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.hostingController.rootView = CalculatorKeypad(
            allowsOperators: allowsOperators,
            doneTitle: doneTitle,
            onKey: onKey
        )

        if isFocused, !uiView.isFirstResponder {
            uiView.isUserInteractionEnabled = true
            uiView.becomeFirstResponder()
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isFocused: $isFocused)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var isFocused: Bool
        let hostingController = UIHostingController(
            rootView: CalculatorKeypad(allowsOperators: true, doneTitle: "Готово", onKey: { _ in })
        )

        init(isFocused: Binding<Bool>) {
            _isFocused = isFocused
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !isFocused { isFocused = true }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if isFocused { isFocused = false }
        }
    }
}
