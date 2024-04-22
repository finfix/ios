//
//  Icon.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation

struct Icon: Identifiable {
    var id: UInt32
    var name: String
    var url: URL?
    
    private let basePath = "https://bonavii.com/"
    
    init(
        id: UInt32 = 0,
        name: String = "",
        url: String = ""
    ) {
        self.id = id
        self.name = name
        if url != "" {
            self.url = URL(string: basePath + url)!
        }
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: IconDB) {
        self.id = dbModel.id
        self.name = dbModel.name
        self.url = URL(string: dbModel.url)!
    }
    
    static func convertFromDBModel(_ iconsDB: [IconDB]) -> [Icon] {
        var icons: [Icon] = []
        for iconDB in iconsDB {
            icons.append(Icon(iconDB))
        }
        return icons
    }
    
    static func convertToMap(_ icons: [Icon]) -> [UInt32: Icon] {
        return Dictionary(uniqueKeysWithValues: icons.map{ ($0.id, $0) })
    }
}

extension Icon: Hashable {
    static func == (lhs: Icon, rhs: Icon) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
