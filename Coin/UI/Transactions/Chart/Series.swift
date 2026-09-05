//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI
import Factory

struct Series: Identifiable, Hashable {
    let id = UUID()
    var account: Account?
    var tag: Tag?
    var type: SeriesType?
    var objectID: UUID?
    var serialNumber: UInt32 = 0
    var color: Color = .white
    var data: [Date: Decimal]
}
