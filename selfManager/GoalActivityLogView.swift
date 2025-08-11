//
//  GoalActivityLogView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import SwiftData

struct GoalActivityLogView: View {
    @Environment(\.dismiss) private var dismiss
    var goal: Goal
    
    // 使用 GoalActivityManager 中定义的 ActivityLogEntry 结构
    typealias ActivityLogEntry = GoalActivityManager.ActivityLogEntry
    
    // 获取活动日志列表
    private var activityLogs: [ActivityLogEntry] {
        // 从 GoalActivityManager 获取活动日志
        let logs = GoalActivityManager.shared.getActivityLogs(for: goal.id)
        
        // 如果没有日志记录，添加一条创建记录
        if logs.isEmpty {
            // 记录目标创建
            GoalActivityManager.shared.logGoalCreation(goal: goal)
            return GoalActivityManager.shared.getActivityLogs(for: goal.id)
        }
        
        return logs
    }
    
    // 获取目标类型显示名称
    private func getGoalTypeDisplayName(_ type: GoalType) -> String {
        switch type {
        case .life:
            return "人生目标"
        case .yearly:
            return "年度目标"
        case .shortTerm:
            return "短期目标"
        case .habit:
            return "习惯"
        }
    }
    
    // 获取重要性显示名称
    private func getImportanceDisplayName(_ importance: Int) -> String {
        switch importance {
        case 1:
            return "低"
        case 2:
            return "中"
        case 3:
            return "高"
        default:
            return "未知"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("目标动态")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(UIColor.systemGray3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            Divider()
            
            if activityLogs.isEmpty {
                // 无数据视图
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(Color(UIColor.systemGray3))
                    
                    Text("暂无活动记录")
                        .font(.system(size: 16))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                // 时间线视图
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(activityLogs.enumerated()), id: \.element.id) { index, log in
                            // 日期分隔线（如果是新的一天或第一条记录）
                            if index == 0 || !isSameDay(date1: activityLogs[index-1].date, date2: log.date) {
                                Text(formatDateHeader(log.date))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                            }
                            
                            // 活动项
                            HStack(alignment: .top, spacing: 15) {
                                // 时间线
                                VStack(spacing: 0) {
                                    // 时间
                                    Text(formatTime(log.date))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                        .frame(width: 45, alignment: .center)
                                    
                                    // 时间线圆点和线
                                    ZStack(alignment: .top) {
                                        // 垂直线
                                        if index < activityLogs.count - 1 {
                                            Rectangle()
                                                .fill(Color(UIColor.systemGray5))
                                                .frame(width: 2, height: 40)
                                        }
                                        
                                        // 圆点
                                        Circle()
                                            .fill(getActivityColor(log.type))
                                            .frame(width: 8, height: 8)
                                    }
                                    .frame(height: 40)
                                }
                                .frame(width: 45)
                                
                                // 活动内容
                                VStack(alignment: .leading, spacing: 8) {
                                    // 活动消息
                                    Text(log.message)
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(UIColor.label))
                                        .multilineTextAlignment(.leading)
                                    
                                    // 如果有旧值和新值，显示变更详情
                                    if let oldValue = log.oldValue, let newValue = log.newValue {
                                        HStack(spacing: 8) {
                                            Text(oldValue)
                                                .font(.system(size: 13))
                                                .foregroundColor(Color(UIColor.systemRed))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color(UIColor.systemRed).opacity(0.1))
                                                .cornerRadius(4)
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                            
                                            Text(newValue)
                                                .font(.system(size: 13))
                                                .foregroundColor(Color(UIColor.systemGreen))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color(UIColor.systemGreen).opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            Divider()
                                .padding(.leading, 65)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // 根据活动类型获取颜色
    private func getActivityColor(_ type: String) -> Color {
        switch type {
        case "create":
            return Color.blue
        case "task_add", "task_complete":
            return Color.green
        case "name_change", "description_change", "progress_change", "type_change", "importance_change", "duedate_change":
            return Color.orange
        case "tag_add", "tag_remove":
            return Color.purple
        case "upper_project_add", "upper_project_remove", "sub_project_add", "sub_project_remove":
            return Color.indigo
        case "contact_add", "contact_remove":
            return Color.pink
        default:
            return Color.gray
        }
    }
    
    // 判断两个日期是否是同一天
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    // 格式化日期头部
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    GoalActivityLogView(goal: createPreviewGoal())
}

// 创建预览用的Goal
@MainActor
func createPreviewGoal() -> Goal {
    let container = try! ModelContainer(for: Goal.self, GoalTask.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let goal = Goal(name: "完成项目开发", description: "在截止日期前完成所有功能开发和测试", progress: 0.6, goalType: .shortTerm, dueDate: Date().addingTimeInterval(86400 * 7), importance: 3)
    
    // 添加一些任务
    let task1 = GoalTask(title: "完成UI设计", isCompleted: true)
    let task2 = GoalTask(title: "实现核心功能", isCompleted: false)
    let task3 = GoalTask(title: "编写单元测试", isCompleted: false)
    
    goal.tasks = [task1, task2, task3]
    container.mainContext.insert(goal)
    
    return goal
}