//
//  Habit.swift
//  selfManager
//
//  Created by Assistant on 2025/1/17.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var icon: String // SF Symbol 图标名称
    var color: String // 颜色标识
    var frequency: HabitFrequency // 频率类型
    var targetCount: Int // 目标次数（每日/每周等）
    var currentStreak: Int // 当前连续天数
    var longestStreak: Int // 最长连续天数
    var totalCompletions: Int // 总完成次数
    var isActive: Bool // 是否激活
    var createTime: Date
    var modifyTime: Date
    
    // 回收站相关字段
    var isDeleted: Bool = false
    var deletedDate: Date?
    
    // 习惯记录关系
    @Relationship(deleteRule: .cascade, inverse: \HabitRecord.habit)
    var records: [HabitRecord] = []
    
    init(name: String, description: String = "", icon: String = "checkmark.circle", color: String = "blue", frequency: HabitFrequency = .daily, targetCount: Int = 1) {
        self.id = UUID()
        self.name = name
        self.habitDescription = description
        self.icon = icon
        self.color = color
        self.frequency = frequency
        self.targetCount = targetCount
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.isActive = true
        self.createTime = Date()
        self.modifyTime = Date()
        self.isDeleted = false
        self.deletedDate = nil
    }
    
    // 软删除方法
    func moveToTrash() {
        self.isDeleted = true
        self.deletedDate = Date()
        self.modifyTime = Date()
    }
    
    // 从回收站恢复
    func restoreFromTrash() {
        self.isDeleted = false
        self.deletedDate = nil
        self.modifyTime = Date()
    }
    
    // 更新连续天数
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 获取最近的记录，按日期排序
        let sortedRecords = records
            .filter { !$0.isDeleted }
            .sorted { $0.completedDate > $1.completedDate }
        
        var streak = 0
        var checkDate = today
        
        // 计算当前连续天数
        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.completedDate)
            
            if calendar.isDate(recordDate, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if recordDate < checkDate {
                // 如果记录日期早于检查日期，说明连续性中断
                break
            }
        }
        
        self.currentStreak = streak
        if streak > longestStreak {
            self.longestStreak = streak
        }
        self.modifyTime = Date()
    }
    
    // 获取今日完成状态
    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return records.contains { record in
            !record.isDeleted && calendar.isDate(record.completedDate, inSameDayAs: today)
        }
    }
    
    // 获取本周完成次数
    func completionsThisWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return records.filter { record in
            !record.isDeleted && record.completedDate >= startOfWeek
        }.count
    }
}

// 习惯频率枚举
enum HabitFrequency: String, CaseIterable, Codable {
    case daily = "每日"
    case weekly = "每周"
    case monthly = "每月"
    
    var iconName: String {
        switch self {
        case .daily:
            return "sun.max"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .daily:
            return Color.orange
        case .weekly:
            return Color.blue
        case .monthly:
            return Color.purple
        }
    }
}

// 习惯记录模型
@Model
final class HabitRecord {
    var id: UUID
    var completedDate: Date
    var note: String // 可选备注
    var createTime: Date
    
    // 回收站相关字段
    var isDeleted: Bool = false
    var deletedDate: Date?
    
    // 关联的习惯
    var habit: Habit?
    
    init(completedDate: Date = Date(), note: String = "") {
        self.id = UUID()
        self.completedDate = completedDate
        self.note = note
        self.createTime = Date()
        self.isDeleted = false
        self.deletedDate = nil
    }
    
    // 软删除方法
    func moveToTrash() {
        self.isDeleted = true
        self.deletedDate = Date()
    }
    
    // 从回收站恢复
    func restoreFromTrash() {
        self.isDeleted = false
        self.deletedDate = nil
    }
}

import SwiftUI

// 习惯颜色扩展
extension Color {
    static func habitColor(from string: String) -> Color {
        switch string.lowercased() {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "blue":
            return .blue
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "gray":
            return .gray
        default:
            return .blue
        }
    }
}