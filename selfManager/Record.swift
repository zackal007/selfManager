//
//  Record.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftData

// 记录类型枚举
enum RecordType: Int, Codable, Hashable {
    case daily = 0   // 日记
    case weekly = 1  // 周记
    case monthly = 2 // 月记
    case quarterly = 3 // 季记
    case yearly = 4  // 年记
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
    var createTime: Date
    
    init(title: String, content: String, recordType: RecordType, year: Int, month: Int? = nil, day: Int? = nil, week: Int? = nil, quarter: Int? = nil, mood: String? = nil, weather: String? = nil) {
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
        self.createTime = Date()
    }
}