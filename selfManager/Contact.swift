//
//  Contact.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import Foundation
import SwiftData

// 联系人类型枚举
enum ContactType: Int, Codable, Hashable, CaseIterable {
    case family = 0      // 家人
    case friend = 1      // 朋友
    case colleague = 2   // 同事
    case business = 3    // 商务
    case mentor = 4      // 导师
    case other = 5       // 其他
    
    var displayName: String {
        switch self {
        case .family: return "家人"
        case .friend: return "朋友"
        case .colleague: return "同事"
        case .business: return "商务"
        case .mentor: return "导师"
        case .other: return "其他"
        }
    }
    
    var iconName: String {
        switch self {
        case .family: return "house.fill"
        case .friend: return "person.2.fill"
        case .colleague: return "briefcase.fill"
        case .business: return "handshake.fill"
        case .mentor: return "graduationcap.fill"
        case .other: return "person.fill"
        }
    }
}

// 联系频率枚举
enum ContactFrequency: Int, Codable, Hashable, CaseIterable {
    case daily = 0       // 每日
    case weekly = 1      // 每周
    case monthly = 2     // 每月
    case quarterly = 3   // 每季度
    case yearly = 4      // 每年
    case occasional = 5  // 偶尔
    
    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .quarterly: return "每季度"
        case .yearly: return "每年"
        case .occasional: return "偶尔"
        }
    }
}

// 重要程度枚举
enum ContactImportance: Int, Codable, Hashable, CaseIterable {
    case low = 0         // 低
    case medium = 1      // 中
    case high = 2        // 高
    case critical = 3    // 关键
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "关键"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

@Model
final class Contact {
    var id: UUID
    var name: String
    var company: String?
    var position: String?
    var phone: String?
    var email: String?
    var address: String?
    var notes: String?
    var contactType: ContactType
    var importance: ContactImportance
    var frequency: ContactFrequency
    var tags: [String]
    var lastContactDate: Date?
    var nextContactDate: Date?
    var createTime: Date
    var modifyTime: Date
    var avatar: String? // 头像图片名称或路径
    
    init(name: String, company: String? = nil, position: String? = nil, phone: String? = nil, email: String? = nil, address: String? = nil, notes: String? = nil, contactType: ContactType = .other, importance: ContactImportance = .medium, frequency: ContactFrequency = .monthly, tags: [String] = [], lastContactDate: Date? = nil, nextContactDate: Date? = nil, avatar: String? = nil) {
        self.id = UUID()
        self.name = name
        self.company = company
        self.position = position
        self.phone = phone
        self.email = email
        self.address = address
        self.notes = notes
        self.contactType = contactType
        self.importance = importance
        self.frequency = frequency
        self.tags = tags
        self.lastContactDate = lastContactDate
        self.nextContactDate = nextContactDate
        self.createTime = Date()
        self.modifyTime = Date()
        self.avatar = avatar
    }
    
    // 计算下次联系提醒时间
    func calculateNextContactDate() -> Date? {
        guard let lastDate = lastContactDate else { return nil }
        
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: lastDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: lastDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: lastDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: lastDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: lastDate)
        case .occasional:
            return nil // 偶尔联系不设置提醒
        }
    }
    
    // 检查是否需要联系提醒
    var needsContactReminder: Bool {
        guard let nextDate = nextContactDate else { return false }
        return nextDate <= Date()
    }
    
    // 更新最后联系时间并计算下次联系时间
    func updateLastContactDate(_ date: Date = Date()) {
        lastContactDate = date
        nextContactDate = calculateNextContactDate()
        modifyTime = Date()
    }
}