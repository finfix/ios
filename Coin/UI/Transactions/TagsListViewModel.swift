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

    var tags: [Tag] = []

    func load() async throws {
        tags = try await service.getTags()
    }
    
    func deleteTag(_ tag: Tag) async throws {
        guard let index = tags.firstIndex(of: tag) else {
            throw ErrorModel(humanTextError: "Не смогли найти позицию подкатегории №\(tag.id) в массиве")
        }
        _ = tags.remove(at: index)
        try await service.deleteTag(tag)
    }

}
