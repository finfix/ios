//
//  FileStorageManager.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation

final class FileStorageManager {
    
    static let shared = FileStorageManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    func retrive() {
        
    }
    
    func save(_ item: Item) {
        
        guard let cacheFolder = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return }
        
        let fileURL = cacheFolder.appendingPathComponent(item.name + ".cache")
        
        do {
            let data = try JSONEncoder().encode(item)
            try data.write(to: fileURL)
        } catch {
            print(error)
        }
    }
}

extension FileStorageManager {
    struct Item: Codable {
        
        let name: String
        let data: Data
        
        init(name: String, data: Data) {
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.data = data
        }
    }
}
