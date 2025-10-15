//
//  BuiltInTags.swift
//  selfManager
//
//  Created by Trae Builder on 2025/10/04.
//

import SwiftUI
import SwiftData

// 系统内置标签常量与工具
struct BuiltInTags {
    // 名称常量
    static let achievement = "成就"
    static let anxiety = "焦虑"
    
    // 系统内置分类名称和ID
    static let systemCategoryName = "系统内置"
    static let systemCategoryID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let systemCategoryDescription = "系统提供的默认标签，用于标记重要的事项类型"
    static let systemCategoryColor = "#FF9500" // 系统橙色

    // 所有内置标签名称集合
    static let allNames: [String] = [achievement, anxiety]

    // 描述
    static let descriptions: [String: String] = [
        achievement: "用于标记你的成果、里程碑与重要达成事项，帮助你回顾并强化正向反馈。",
        anxiety: "用于标记让你感到焦虑的事物，帮助觉察压力来源并进行缓解与管理。"
    ]

    // 固定颜色（成就：金色；焦虑：橙色）
    static func color(for tag: String) -> Color {
        switch normalize(tag) {
        case normalize(achievement):
            return Color(hex: "#FFD700") ?? Color(UIColor.systemYellow) // Gold
        case normalize(anxiety):
            return Color(hex: "#FF8C00") ?? Color(UIColor.systemOrange) // DarkOrange
        default:
            return Color(UIColor.systemBlue)
        }
    }

    // 是否为系统内置标签
    static func isBuiltIn(_ tag: String) -> Bool {
        let n = normalize(tag)
        return allNames.map { normalize($0) }.contains(n)
    }

    // 规范化（去空白、统一大小写）
    private static func normalize(_ tag: String) -> String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // 确保内置标签写入数据库（若缺失则插入）
    static func ensureExists(modelContext: ModelContext) {
        // 首先确保系统内置分类存在
        ensureSystemCategoryExists(modelContext: modelContext)
        
        for name in allNames {
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == name })
            let exists = (try? modelContext.fetch(descriptor))?.first != nil
            if !exists {
                let description = descriptions[name] ?? ""
                let tag = Tag(name: name, tagDescription: description, color: "", categoryID: systemCategoryID)
                modelContext.insert(tag)
            }
        }
    }
    
    // 确保系统内置分类存在
    private static func ensureSystemCategoryExists(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TagCategory>(predicate: #Predicate<TagCategory> { $0.id == systemCategoryID })
        let exists = (try? modelContext.fetch(descriptor))?.first != nil
        if !exists {
            let category = TagCategory(
                name: systemCategoryName,
                categoryDescription: systemCategoryDescription,
                color: systemCategoryColor
            )
            category.id = systemCategoryID
            modelContext.insert(category)
        }
    }
}