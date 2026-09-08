//
//  RecordCardView.swift
//  selfManager
//
//  Created by Assistant on 2024.12.20.
//

import SwiftUI
import Foundation

struct RecordCardView: View {
    let record: Record
    let onTap: () -> Void
    
    // ISO 8601 周显示辅助：按指定时区计算 week/year（周基年）
    static func isoWeekDisplay(for date: Date, timeZone: TimeZone = .current) -> String {
        var isoCalendar = Calendar(identifier: .iso8601)
        isoCalendar.timeZone = timeZone
        let yearForWeek = isoCalendar.component(.yearForWeekOfYear, from: date)
        let weekOfYear = isoCalendar.component(.weekOfYear, from: date)
        return "\(yearForWeek)年第\(weekOfYear)周"
    }
    
    private var formattedDate: String {
        // 根据记录类型决定日期显示格式
        switch record.recordType {
        case .weekly:
            if let wk = record.week {
                return "\(record.year)年第\(wk)周"
            } else {
                var cal = Calendar.current
                cal.firstWeekday = 1
                let year = cal.component(.year, from: record.createTime)
                let week = cal.component(.weekOfYear, from: record.createTime)
                return "\(year)年第\(week)周"
            }
        case .monthly:
            // 月记显示为月模式
            return "\(record.year)年\(record.month ?? 1)月"
        case .quarterly:
            // 季记显示为季模式
            // 直接使用记录中存储的季度信息，而不是从月份计算
            let quarter = record.quarter ?? 1
            return "\(record.year)年第\(quarter)季度"
        case .yearly:
            // 年记显示为年模式
            return "\(record.year)年"
        default:
            // 其他类型显示为日模式
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            // 根据记录的实际日期信息构建日期
            var dateComponents = DateComponents()
            dateComponents.year = record.year
            dateComponents.month = record.month
            dateComponents.day = record.day
            
            let calendar = Calendar.current
            if let actualDate = calendar.date(from: dateComponents) {
                return formatter.string(from: actualDate)
            } else {
                // 如果无法构建日期，则回退到创建时间
                return formatter.string(from: record.createTime)
            }
        }
    }
    
    private var recordTitle: String {
        // 从内容中提取第一行作为标题
        let lines = record.content.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return firstLine.isEmpty ? "无标题" : firstLine
    }
    
    private var contentPreview: String {
        // 获取内容预览，去除第一行后的内容
        let lines = record.content.components(separatedBy: .newlines)
        let previewLines = Array(lines.dropFirst()).joined(separator: " ")
        let preview = previewLines.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 限制预览长度
        if preview.count > 100 {
            let index = preview.index(preview.startIndex, offsetBy: 100)
            return String(preview[..<index]) + "..."
        }
        return preview.isEmpty ? "暂无内容" : preview
    }
    
    private var recordTypeColor: Color {
        switch record.recordType {
        case .daily:
            return Color("AppBlue")
        case .weekly:
            return .green
        case .monthly:
            return Color("AppOrange")
        case .quarterly:
            return .purple
        case .yearly:
            return .red
        case .recent:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 顶部信息栏：日期和记录类型
                HStack {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // 标题
                Text(recordTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 内容预览
                if !contentPreview.isEmpty && contentPreview != "暂无内容" {
                    Text(contentPreview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // 底部信息：心情和天气（如果有）
                if record.mood != nil || record.weather != nil {
                    HStack(spacing: 8) {
                        if let mood = record.mood {
                            Text(mood)
                                .font(.caption)
                        }
                        
                        if let weather = record.weather {
                            Text(weather)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(DesignToken.cornerRadiusMedium)
            // 统一卡片与页面背景色：移除阴影以避免视觉差异
            // 移除边框以与页面背景视觉统一
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// 按钮样式：添加轻微的缩放效果
struct RecordCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

#Preview {
    let sampleRecord = Record(
        title: "示例记录",
        content: "这是一个示例记录的标题\n这里是记录的详细内容，用于展示卡片的预览效果。内容可能会很长，需要进行截断处理。",
        recordType: .daily,
        year: 2024,
        month: 12,
        day: 20,
        mood: "😊",
        weather: "☀️"
    )
    
    RecordCardView(record: sampleRecord) {
        print("卡片被点击")
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}