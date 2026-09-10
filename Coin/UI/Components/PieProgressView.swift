//
//  PieProgressView.swift
//  Coin
//

import SwiftUI

/// Закрашенный сектор круга (как "пирог"), заполняющийся по часовой стрелке от 12 часов —
/// используется вместо стандартного indeterminate-спиннера там, где есть реальный прогресс
/// (0...1) и хочется явно показать, что он растёт, а не просто "что-то происходит".
struct PieShape: Shape {
    /// 0...1
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        guard progress > 0 else { return path }
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct PieProgressView: View {
    /// 0...1
    var progress: Double
    var diameter: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)
            PieShape(progress: progress)
                .fill(Color.accentColor)
                .padding(1.5)
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
}

#Preview {
    PieProgressView(progress: 0.35, diameter: 60)
}
