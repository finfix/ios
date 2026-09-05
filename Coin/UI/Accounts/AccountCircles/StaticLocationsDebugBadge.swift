//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

/// Индикатор для дебага static locations — показывает момент первой регистрации позиции с
/// момента появления/пересоздания экрана и живой "прошло N мс с этого момента", чтобы можно было
/// на глаз сопоставить его с моментом, когда счета визуально появились (см. отчёт про баг
/// "static locations иногда не регистрируются при первом появлении экрана").
struct StaticLocationsDebugBadge: View {
    let startedAt: Date?
    let count: Int

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
            HStack(spacing: 6) {
                Circle()
                    .fill(startedAt == nil ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                if let startedAt {
                    Text("static locations: старт \(Self.timeFormatter.string(from: startedAt)), +\(Int(context.date.timeIntervalSince(startedAt) * 1000))мс, зарегистрировано \(count)")
                } else {
                    Text("static locations: ещё ни одной регистрации")
                }
            }
            .font(.caption2.monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.7), in: Capsule())
            .foregroundColor(.white)
        }
    }
}
