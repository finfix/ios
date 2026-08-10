//
//  AuditLogHistoryViewModel.swift
//  Coin
//

import Foundation
import Factory

@Observable
class AuditLogHistoryViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    let entity: AuditLogEntity
    let entityID: String
    let accountGroupID: UUID?

    var logs: [AuditLog] = []
    var isLoadingNextPage = false
    var hasMore = true

    private let pageSize: UInt32 = 20

    init(entity: AuditLogEntity, entityID: String, accountGroupID: UUID?) {
        self.entity = entity
        // Бэкенд хранит entityID в нижнем регистре (Go uuid.String()), а UUID.uuidString
        // на клиенте всегда в верхнем — без приведения фильтр по entityID не совпадёт.
        self.entityID = entityID.lowercased()
        self.accountGroupID = accountGroupID
    }

    func loadFirstPage() async throws {
        hasMore = true
        logs = try await service.getAuditLogs(
            accountGroupID: accountGroupID,
            entity: entity,
            entityID: entityID,
            limit: pageSize,
            offset: 0
        )
        hasMore = logs.count == pageSize
    }

    private func loadNextPage() async throws {
        guard !isLoadingNextPage, hasMore else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let page = try await service.getAuditLogs(
            accountGroupID: accountGroupID,
            entity: entity,
            entityID: entityID,
            limit: pageSize,
            offset: UInt32(logs.count)
        )
        logs.append(contentsOf: page)
        hasMore = page.count == pageSize
    }

    /// "Умная" пагинация: следующая страница подгружается только когда пользователь
    /// долистал до последнего элемента текущего списка ("до дна"), а не заранее.
    func loadMoreIfNeeded(currentItem: AuditLog) {
        guard logs.last?.id == currentItem.id else { return }
        Task {
            try? await loadNextPage()
        }
    }
}
