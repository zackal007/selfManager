//
//  TagCategory.swift
//  selfManager
//
//  Created by Trae AI on 2024/12/31.
//

import Foundation
import SwiftData

@Model
final class TagCategory {
    var id: UUID
    var name: String
    var categoryDescription: String
    var color: String
    var createTime: Date
    var modifyTime: Date
    
    init(name: String, categoryDescription: String = "", color: String = "") {
        self.id = UUID()
        self.name = name
        self.categoryDescription = categoryDescription
        self.color = color
        self.createTime = Date()
        self.modifyTime = Date()
    }
}