//
//  EditTagViewModel.swift
//  Coin
//
//  Created by Илья on 22.04.2024.
//

import Foundation
import SwiftUI
import Factory

@Observable
class EditTagViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
        
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
