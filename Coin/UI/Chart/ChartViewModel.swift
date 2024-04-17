//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation

@Observable
class ChartViewModel {
    
    let service = Service.shared
    
    var data: [Series] = []
    
    func load(accountGroupID: UInt32) async throws {
        data = try await service.getStatisticByMonth(accountGroupID: accountGroupID)
    }
}

struct Series {
    
    let name: String
    let data: [Date: Decimal]
}
