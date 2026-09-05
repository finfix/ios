//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI
import Factory

enum SeriesType: Hashable {
    case income, expense
    
    var name: String {
        switch self {
        case .income: "Доход"
        case .expense: "Расход"
        }
    }
}
