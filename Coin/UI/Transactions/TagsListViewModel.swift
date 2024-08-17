//
//  TagsListViewModel.swift
//  Coin
//
//  Created by Илья on 21.04.2024.
//

import Foundation

@Observable
class TagsListViewModel {
    private let service = Service.shared

    var accountGroup = AccountGroup()
    var tags: [Tag] = []
    
    init(
        accountGroup: AccountGroup
    ) {
        self.accountGroup = accountGroup
    }

    func load() async throws {
        tags = try await service.getTags(accountGroup: accountGroup)
    }
    
    func deleteTag(_ tag: Tag) async throws {
        guard let index = tags.firstIndex(of: tag) else {
            throw ErrorModel(humanText: "Не смогли найти позицию подкатегории №\(tag.id) в массиве")
        }
        _ = tags.remove(at: index)
        try await service.deleteTag(tag)
    }

}
