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
    private var accountIDs: [UInt32] {
        var ids: [UInt32] = []
        if let account = account {
            ids = [account.id]
            for childAccount in account.childrenAccounts {
                ids.append(childAccount.id)
            }
        }
        return ids
    }
    
    init(
        chartType: ChartType,
        account: Account? = nil
    ) {
        self.chartType = chartType
        self.account = account
    }
    
    var account: Account?
    
    func load(accountGroupID: UInt32) async throws {
        data = try await service.getStatisticByMonth(chartType: chartType, accountGroupID: accountGroupID, accountIDs: accountIDs)
    }
}

struct Series: Identifiable, Hashable {
    let id = UUID()
    var account: Account?
    var type: String
    var color: Color = .white
    var data: [Date: Decimal]
}
