//
//  TagService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation

extension Service {
    
    // MARK: Create
    func createTag(_ tag: Tag) async throws {
        var tag = tag
        
        tag.datetimeCreate = Date.now
                
        try await repository.createTag(tag)
        
        try await taskManager.createTask(
            actionName: .createTag,
            reqModel: CreateTagReq(
                id: tag.id,
                name: tag.name,
                accountGroupID: tag.accountGroup.id,
                datetimeCreate: tag.datetimeCreate
            ),
            entityID: tag.id,
            dependsOnEntityIDs: [tag.accountGroup.id]
        )
    }
    
    // MARK: Read
    func getTags(
        accountGroup: AccountGroup? = nil,
        name: String? = nil
    ) async throws -> [Tag] {
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await repository.getAccountGroups(), currenciesMap: nil))
        return Tag.convertFromDBModel(try await repository.getTags(
            accountGroupID: accountGroup?.id,
            name: name
        ), accountGroupsMap: accountGroupsMap)
    }
    
    // MARK: Update
    func updateTag(newTag tag: Tag, oldTag: Tag) async throws {
        var newTag = tag
        
        guard tag.name != "" else {
            throw ErrorModel(humanText: "Нельзя создать подкатегорию без названия")
        }
                
        try await repository.updateTag(newTag)
        
        try await taskManager.createTask(
            actionName: .updateTag,
            reqModel: UpdateTagReq(
                id: newTag.id,
                name: newTag.name != oldTag.name ? newTag.name : nil
            ),
            entityID: newTag.id
        )
    }
    
    // MARK: Delete
    func deleteTag(_ tag: Tag) async throws {
        try await self.repository.deleteTag(tag)
        try await taskManager.createTask(
            actionName: .deleteTag,
            reqModel: DeleteTagReq(id: tag.id),
            entityID: tag.id
        )
    }
}
