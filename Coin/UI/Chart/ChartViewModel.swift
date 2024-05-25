//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI

enum ChartType: String, CaseIterable {
    case earningsAndExpenses = "Доходы и расходы"
    case earnings = "Доходы"
    case expenses = "Расходы"
}

@Observable
class ChartViewModel {
    
    let service = Service.shared
    
    var chartType: ChartType
    var data: [Series] = []
    var filters: TransactionFilters
    
    init(
        chartType: ChartType,
        filters: TransactionFilters
    ) {
        self.chartType = chartType
        self.filters = filters
    }
        
    func load(accountGroupID: UInt32) async throws {
        
        var accountIDs: [UInt32] = []
        if let account = filters.account {
            accountIDs = [account.id]
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }

        data = try await service.getStatisticByMonth(chartType: chartType, accountGroupID: accountGroupID, accountIDs: accountIDs)
    }
}

struct Series: Identifiable, Hashable {
    let id = UUID()
    var account: Account?
    var type: String
    var serialNumber: UInt32 = 0
    var color: Color = .white
    var data: [Date: Decimal]
}
