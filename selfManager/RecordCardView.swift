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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: record.createTime)
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
            return .blue
        case .weekly:
            return .green
        case .monthly:
            return .orange
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
                    
                    Text(record.recordType.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(recordTypeColor)
                        .cornerRadius(8)
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
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// 按钮样式：添加轻微的缩放效果
struct RecordCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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