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

/// Делает текст "копируемым по тапу": по нажатию кладёт `text` в буфер обмена
/// и на секунду показывает рядом плашку `CopyToast`.
struct CopyableOnTap: ViewModifier {
    var text: String

    @State private var showCopiedBadge = false

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIPasteboard.general.string = text
                withAnimation {
                    showCopiedBadge = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    withAnimation {
                        showCopiedBadge = false
                    }
                }
            }
            .overlay(alignment: .center) {
                CopyToast(isVisible: showCopiedBadge)
            }
    }
}

extension View {
    func copyableOnTap(_ text: String) -> some View {
        modifier(CopyableOnTap(text: text))
    }
}
