//
//  EditTagViewModel.swift
//  Coin
//
//  Created by Илья on 22.04.2024.
//

import Foundation
import SwiftUI

@Observable
class EditTagViewModel {
    private let service = Service.shared
        
    var currentTag = Tag()
    var oldTag = Tag()
    var mode: mode
    
    init(
        currentTag: Tag,
        oldTag: Tag = Tag(),
        mode: mode
    ) {
        self.currentTag = currentTag
        self.oldTag = oldTag
        self.mode = mode
    }
            
    func load() async throws {}
    
    func createTag() async throws {
        try await service.createTag(currentTag)
    }
    
    func updateTag() async throws {
        try await service.updateTag(newTag: currentTag, oldTag: oldTag)
    }
}
