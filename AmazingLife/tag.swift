//
//  Tag.swift
//  selfManager
//
//  Created by Trae AI on 2024/12/31.
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var tagDescription: String
    var color: String
    var categoryID: UUID?
    var createTime: Date
    var modifyTime: Date
    
    // 计算属性，获取标签分类
    @Transient
    var category: TagCategory? {
        guard let categoryID = categoryID else { return nil }
        let descriptor = FetchDescriptor<TagCategory>(predicate: #Predicate<TagCategory> { $0.id == categoryID })
        return try? modelContext?.fetch(descriptor).first
    }
    
    init(name: String, tagDescription: String = "", color: String = "", categoryID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.tagDescription = tagDescription
        self.color = color
        self.categoryID = categoryID
        self.createTime = Date()
        self.modifyTime = Date()
    }
}