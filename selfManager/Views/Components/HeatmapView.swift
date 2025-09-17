//
//  HeatmapView.swift
//  selfManager
//
//  Created by Assistant on 2025/1/17.
//

import SwiftUI
import SwiftData

// 热力图数据模型
struct HeatmapData {
    let date: Date
    let count: Int
    let level: Int // 0-4 强度等级
    
    init(date: Date, count: Int) {
        self.date = date
        self.count = count
        // 根据记录数量计算强度等级
        if count == 0 {
            self.level = 0
        } else if count <= 2 {
            self.level = 1
        } else if count <= 5 {
            self.level = 2
        } else if count <= 10 {
            self.level = 3
        } else {
            self.level = 4
        }
    }
}

// 记录热力图组件
struct HeatmapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    private let weeksToShow = 20 // 显示20周的数据
    
    // 获取热力图数据
    private func getHeatmapData() -> [HeatmapData] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeksToShow, to: today) ?? today
        
        var heatmapData: [HeatmapData] = []
        var currentDate = startDate
        
        while currentDate <= today {
            let dayGoals = goals.filter { goal in
                !goal.isDeleted && calendar.isDate(goal.createTime, inSameDayAs: currentDate)
            }
            
            heatmapData.append(HeatmapData(date: currentDate, count: dayGoals.count))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return heatmapData
    }
    
    // 获取颜色
    private func getColor(for level: Int) -> Color {
        switch level {
        case 0:
            return Color(UIColor.systemGray6)
        case 1:
            return Color(UIColor.systemGreen).opacity(0.3)
        case 2:
            return Color(UIColor.systemGreen).opacity(0.5)
        case 3:
            return Color(UIColor.systemGreen).opacity(0.7)
        case 4:
            return Color(UIColor.systemGreen)
        default:
            return Color(UIColor.systemGray6)
        }
    }
    
    // 将数据按周分组
    private func groupDataByWeeks(_ data: [HeatmapData]) -> [[HeatmapData]] {
        let calendar = Calendar.current
        var weeks: [[HeatmapData]] = []
        var currentWeek: [HeatmapData] = []
        
        for item in data {
            let weekday = calendar.component(.weekday, from: item.date)
            
            // 如果是周一（weekday == 2）且当前周不为空，开始新的一周
            if weekday == 2 && !currentWeek.isEmpty {
                weeks.append(currentWeek)
                currentWeek = []
            }
            
            currentWeek.append(item)
        }
        
        // 添加最后一周
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }
        
        return weeks
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和统计信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("记录热力图")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    
                    let totalRecords = getHeatmapData().reduce(0) { $0 + $1.count }
                    Text("过去\(weeksToShow)周共\(totalRecords)条记录")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                // 强度说明
                HStack(spacing: 4) {
                    Text("少")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getColor(for: level))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text("多")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            // 热力图网格
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // 月份标签
                    HStack(spacing: 0) {
                        let weeks = groupDataByWeeks(getHeatmapData())
                        ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                            if let firstDay = week.first?.date {
                                let calendar = Calendar.current
                                let isFirstWeekOfMonth = calendar.component(.weekOfMonth, from: firstDay) == 1
                                
                                VStack {
                                    if isFirstWeekOfMonth {
                                        Text(DateFormatter.monthFormatter.string(from: firstDay))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                    } else {
                                        Text("")
                                            .font(.system(size: 10))
                                    }
                                }
                                .frame(width: cellSize + cellSpacing)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // 热力图主体
                    HStack(alignment: .top, spacing: 0) {
                        // 星期标签
                        VStack(spacing: cellSpacing) {
                            ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                                    .frame(width: 16, height: cellSize)
                            }
                        }
                        .padding(.trailing, 8)
                        
                        // 热力图网格
                        HStack(spacing: cellSpacing) {
                            let weeks = groupDataByWeeks(getHeatmapData())
                            ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                                VStack(spacing: cellSpacing) {
                                    // 确保每周都有7天的数据
                                    ForEach(0..<7) { dayIndex in
                                        if dayIndex < week.count {
                                            let data = week[dayIndex]
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(getColor(for: data.level))
                                                .frame(width: cellSize, height: cellSize)
                                        } else {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.clear)
                                                .frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// 日期格式化器扩展
extension DateFormatter {
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter
    }()
}

#Preview {
    HeatmapView()
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
}