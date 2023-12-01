//
//  Line.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

#Preview {
    Line()
}
