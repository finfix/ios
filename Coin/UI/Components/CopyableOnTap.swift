//
//  CopyToast.swift
//  Coin
//

import SwiftUI

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
