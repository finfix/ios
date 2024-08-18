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
                
        let id = try await repository.createTag(tag)
        
        taskManager.createTask(
            actionName: .createTag,
            localObjectID: id,
            reqModel: CreateTagReq(
                name: tag.name,
                accountGroupID: tag.accountGroup.id,
                datetimeCreate: tag.datetimeCreate
            )
        )
    }
    
    // MARK: Read
    func getTags(
        accountGroup: AccountGroup? = nil
    ) async throws -> [Tag] {
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await repository.getAccountGroups(), currenciesMap: nil))
        return Tag.convertFromDBModel(try await repository.getTags(
            accountGroupID: accountGroup?.id
        ), accountGroupsMap: accountGroupsMap)
    }
    
    // MARK: Update
    func updateTag(newTag tag: Tag, oldTag: Tag) async throws {
        var newTag = tag
        
        guard tag.name != "" else {
            throw ErrorModel(humanText: "Нельзя создать подкатегорию без названия")
        }
                
        try await repository.updateTag(newTag)
        
        taskManager.createTask(
            actionName: .updateTag,
            localObjectID: newTag.id,
            reqModel: UpdateTagReq(
                id: newTag.id,
                name: newTag.name != oldTag.name ? newTag.name : nil
            )
        )
    }
    
    // MARK: Delete
    func deleteTag(_ tag: Tag) async throws {
        try await self.repository.deleteTag(tag)
        taskManager.createTask(
            actionName: .deleteTag,
            localObjectID: tag.id,
            reqModel: DeleteTagReq(id: tag.id)
        )
    }
}
