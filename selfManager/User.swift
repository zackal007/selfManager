import Foundation
import SwiftData

@Model
class User {
    var name: String
    var avatar: String // e.g., emoji or image name
    var tags: [String]
    var userDescription: String
    
    init(name: String = "张三", avatar: String = "👤", tags: [String] = ["自律", "高效", "成长"], userDescription: String = "热爱生活，追求自我提升的普通人") {
        self.name = name
        self.avatar = avatar
        self.tags = tags
        self.userDescription = userDescription
    }
}