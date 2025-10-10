import Foundation
import SwiftData

struct UserCustomInfo: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var key: String
    var value: String
}

@Model
class User {
    var name: String
    var avatar: String // e.g., emoji or image name
    var tagsString: String = ""
    var customInfosString: String = ""
    
    // 计算属性，用于获取和设置标签数组
    var tags: [String] {
        get {
            return tagsString.isEmpty ? [] : tagsString.components(separatedBy: ",")
        }
        set {
            tagsString = newValue.joined(separator: ",")
        }
    }
    var userDescription: String
    var trashExpirationDays: Int = 30 // 回收站内容的默认过期时间（天）
    
    // 自定义信息（名称-内容键值对）的计算属性，基于 JSON 字符串存储
    var customInfos: [UserCustomInfo] {
        get {
            guard !customInfosString.isEmpty, let data = customInfosString.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([UserCustomInfo].self, from: data)) ?? []
        }
        set {
            let data = (try? JSONEncoder().encode(newValue))
            customInfosString = String(data: data ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
        }
    }
    
    init(name: String = "张三", avatar: String = "👤", tags: [String] = [], userDescription: String = "热爱生活，追求自我提升的普通人", trashExpirationDays: Int = 30, customInfos: [UserCustomInfo] = []) {
        self.name = name
        self.avatar = avatar
        self.tagsString = tags.joined(separator: ",")
        self.userDescription = userDescription
        self.trashExpirationDays = trashExpirationDays
        // 初始化自定义信息
        let data = (try? JSONEncoder().encode(customInfos))
        self.customInfosString = String(data: data ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
    }
}