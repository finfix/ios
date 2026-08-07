//
//  CopyableIDText.swift
//  Coin
//

import SwiftUI

/// Строка "ID: <значение>" — тап копирует id в буфер обмена и на секунду
/// показывает рядом плашку "Скопировано".
struct CopyableIDText: View {
    var id: String

    @State private var showCopiedBadge = false

    var body: some View {
        Button {
            UIPasteboard.general.string = id
            withAnimation {
                showCopiedBadge = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation {
                    showCopiedBadge = false
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("ID: \(id)")
                if showCopiedBadge {
                    Text("Скопировано")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().fill(Color.green.opacity(0.2))
                        }
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
