//
//  TextDiff.swift
//  Coin
//

import Foundation

struct DiffLine: Identifiable {
    let id = UUID()
    let kind: DiffLineKind
    let text: String
}
