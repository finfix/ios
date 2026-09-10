//
//  CopyToast.swift
//  Coin
//

import SwiftUI

/// Плашка "Скопировано", на секунду появляющаяся рядом с текстом после копирования.
struct CopyToast: View {
    var isVisible: Bool

    var body: some View {
        if isVisible {
            Text("Скопировано")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule().fill(Color.green)
                }
                .foregroundStyle(.white)
                .transition(.opacity)
        }
    }
}


extension View {
    func copyableOnTap(_ text: String) -> some View {
        modifier(CopyableOnTap(text: text))
    }
}
