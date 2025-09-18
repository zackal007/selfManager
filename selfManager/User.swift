import Foundation
import SwiftData

@Model
class User {
    var name: String
    var avatar: String // e.g., emoji or image name
    var tagsString: String = ""
    
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
    
    init(name: String = "张三", avatar: String = "👤", tags: [String] = [], userDescription: String = "热爱生活，追求自我提升的普通人", trashExpirationDays: Int = 30) {
        self.name = name
        self.avatar = avatar
        self.tagsString = tags.joined(separator: ",")
        self.userDescription = userDescription
        self.trashExpirationDays = trashExpirationDays
    }
}