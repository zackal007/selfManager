//
//  Record.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftData

// 记录类型枚举
enum RecordType: Int, Codable, Hashable, CaseIterable {
    case recent = 0  // 近期
    case daily = 1   // 日记
    case weekly = 2  // 周记
    case monthly = 3 // 月记
    case quarterly = 4 // 季记
    case yearly = 5  // 年记
    
    var displayName: String {
        switch self {
        case .recent: return "record_tab_recent".localized
        case .daily: return "record_tab_daily".localized
        case .weekly: return "record_tab_weekly".localized
        case .monthly: return "record_tab_monthly".localized
        case .quarterly: return "record_tab_quarterly".localized
        case .yearly: return "record_tab_yearly".localized
        }
    }
}

@Model
final class Record {
    var id: UUID
    var title: String
    var content: String
    var recordType: RecordType
    var year: Int
    var month: Int?
    var day: Int?
    var week: Int?
    var quarter: Int?
    var mood: String?
    var weather: String?
    var images: [Data]?
    var createTime: Date
    
    init(title: String, content: String, recordType: RecordType, year: Int, month: Int? = nil, day: Int? = nil, week: Int? = nil, quarter: Int? = nil, mood: String? = nil, weather: String? = nil, images: [Data]? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.recordType = recordType
        self.year = year
        self.month = month
        self.day = day
        self.week = week
        self.quarter = quarter
        self.mood = mood
        self.weather = weather
        self.images = images
        self.createTime = Date()
    }
}