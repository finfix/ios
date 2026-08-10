//
//  DiffView.swift
//  Coin
//

import SwiftUI

/// Построчный diff в стиле git diff: "-" красным для удалённых строк, "+" зелёным для
/// добавленных, без префикса для неизменных.
struct DiffView: View {
    let old: String
    let new: String

    private var lines: [DiffLine] {
        TextDiff.lineDiff(old: old, new: new)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(lines) { line in
                HStack(alignment: .top, spacing: 6) {
                    Text(prefix(for: line.kind))
                        .foregroundStyle(color(for: line.kind))
                    Text(line.text)
                        .foregroundStyle(line.kind == .unchanged ? .primary : color(for: line.kind))
                }
                .font(.system(.footnote, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .background(background(for: line.kind))
            }
        }
    }

    private func prefix(for kind: DiffLineKind) -> String {
        switch kind {
        case .unchanged: return " "
        case .added: return "+"
        case .removed: return "-"
        }
    }

    private func color(for kind: DiffLineKind) -> Color {
        switch kind {
        case .unchanged: return .primary
        case .added: return .green
        case .removed: return .red
        }
    }

    private func background(for kind: DiffLineKind) -> Color {
        switch kind {
        case .unchanged: return .clear
        case .added: return .green.opacity(0.12)
        case .removed: return .red.opacity(0.12)
        }
    }
}

#Preview {
    ScrollView {
        DiffView(
            old: "{\n  \"name\": \"Тинькофф\",\n  \"remainder\": 100\n}",
            new: "{\n  \"name\": \"Т-Банк\",\n  \"remainder\": 150\n}"
        )
    }
}
