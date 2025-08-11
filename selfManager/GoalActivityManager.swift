//
//  GoalActivityManager.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftData

// 目标活动日志管理器
class GoalActivityManager {
    static let shared = GoalActivityManager()
    
    private init() {}
    
    // 活动日志条目结构
    struct ActivityLogEntry: Identifiable, Codable {
        let id: UUID
        let goalId: UUID
        let date: Date
        let type: String // 创建、修改名称、修改描述、修改进度等
        let oldValue: String?
        let newValue: String?
        let message: String
        
        init(goalId: UUID, type: String, oldValue: String? = nil, newValue: String? = nil, message: String) {
            self.id = UUID()
            self.goalId = goalId
            self.date = Date()
            self.type = type
            self.oldValue = oldValue
            self.newValue = newValue
            self.message = message
        }
    }
    
    // 用于存储活动日志的UserDefaults键
    private let activityLogsKey = "goalActivityLogs"
    
    // 获取指定目标的所有活动日志
    func getActivityLogs(for goalId: UUID) -> [ActivityLogEntry] {
        let allLogs = getAllActivityLogs()
        return allLogs.filter { $0.goalId == goalId }.sorted(by: { $0.date > $1.date })
    }
    
    // 获取所有活动日志
    private func getAllActivityLogs() -> [ActivityLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: activityLogsKey) else { return [] }
        
        do {
            return try JSONDecoder().decode([ActivityLogEntry].self, from: data)
        } catch {
            print("Error decoding activity logs: \(error)")
            return []
        }
    }
    
    // 保存活动日志
    private func saveActivityLogs(_ logs: [ActivityLogEntry]) {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: activityLogsKey)
        } catch {
            print("Error encoding activity logs: \(error)")
        }
    }
    
    // 添加活动日志
    func addActivityLog(goalId: UUID, type: String, oldValue: String? = nil, newValue: String? = nil, message: String) {
        let newLog = ActivityLogEntry(goalId: goalId, type: type, oldValue: oldValue, newValue: newValue, message: message)
        var allLogs = getAllActivityLogs()
        allLogs.append(newLog)
        saveActivityLogs(allLogs)
    }
    
    // 记录目标创建
    func logGoalCreation(goal: Goal) {
        addActivityLog(
            goalId: goal.id,
            type: "create",
            newValue: goal.name,
            message: "创建了目标"
        )
    }
    
    // 记录目标名称修改
    func logNameChange(goal: Goal, oldName: String) {
        addActivityLog(
            goalId: goal.id,
            type: "name_change",
            oldValue: oldName,
            newValue: goal.name,
            message: "修改了目标名称"
        )
    }
    
    // 记录目标描述修改
    func logDescriptionChange(goal: Goal, oldDescription: String) {
        addActivityLog(
            goalId: goal.id,
            type: "description_change",
            oldValue: oldDescription,
            newValue: goal.goalDescription,
            message: "修改了目标描述"
        )
    }
    
    // 记录目标进度修改
    func logProgressChange(goal: Goal, oldProgress: Double) {
        addActivityLog(
            goalId: goal.id,
            type: "progress_change",
            oldValue: String(format: "%.0f%%", oldProgress * 100),
            newValue: String(format: "%.0f%%", goal.progress * 100),
            message: "修改了目标进度"
        )
    }
    
    // 记录目标类型修改
    func logTypeChange(goal: Goal, oldType: GoalType) {
        let oldTypeString = getGoalTypeDisplayName(oldType)
        let newTypeString = getGoalTypeDisplayName(goal.goalType)
        
        addActivityLog(
            goalId: goal.id,
            type: "type_change",
            oldValue: oldTypeString,
            newValue: newTypeString,
            message: "修改了目标类型"
        )
    }
    
    // 记录目标重要性修改
    func logImportanceChange(goal: Goal, oldImportance: Int) {
        let oldImportanceString = getImportanceDisplayName(oldImportance)
        let newImportanceString = getImportanceDisplayName(goal.importance)
        
        addActivityLog(
            goalId: goal.id,
            type: "importance_change",
            oldValue: oldImportanceString,
            newValue: newImportanceString,
            message: "修改了目标重要性"
        )
    }
    
    // 记录目标截止日期修改
    func logDueDateChange(goal: Goal, oldDueDate: Date?) {
        let oldDateString = oldDueDate != nil ? formatDate(oldDueDate!) : "无截止日期"
        let newDateString = goal.dueDate != nil ? formatDate(goal.dueDate!) : "无截止日期"
        
        addActivityLog(
            goalId: goal.id,
            type: "duedate_change",
            oldValue: oldDateString,
            newValue: newDateString,
            message: "修改了截止日期"
        )
    }
    
    // 记录标签添加
    func logTagAdd(goal: Goal, tag: String) {
        addActivityLog(
            goalId: goal.id,
            type: "tag_add",
            newValue: tag,
            message: "添加了标签: \(tag)"
        )
    }
    
    // 记录标签删除
    func logTagRemove(goal: Goal, tag: String) {
        addActivityLog(
            goalId: goal.id,
            type: "tag_remove",
            oldValue: tag,
            message: "删除了标签: \(tag)"
        )
    }
    
    // 记录上级目标添加
    func logUpperProjectAdd(goal: Goal, upperProject: String) {
        addActivityLog(
            goalId: goal.id,
            type: "upper_project_add",
            newValue: upperProject,
            message: "添加了上级目标: \(upperProject)"
        )
    }
    
    // 记录上级目标删除
    func logUpperProjectRemove(goal: Goal, upperProject: String) {
        addActivityLog(
            goalId: goal.id,
            type: "upper_project_remove",
            oldValue: upperProject,
            message: "删除了上级目标: \(upperProject)"
        )
    }
    
    // 记录子目标添加
    func logSubProjectAdd(goal: Goal, subProject: String) {
        addActivityLog(
            goalId: goal.id,
            type: "sub_project_add",
            newValue: subProject,
            message: "添加了子目标: \(subProject)"
        )
    }
    
    // 记录子目标删除
    func logSubProjectRemove(goal: Goal, subProject: String) {
        addActivityLog(
            goalId: goal.id,
            type: "sub_project_remove",
            oldValue: subProject,
            message: "删除了子目标: \(subProject)"
        )
    }
    
    // 记录任务添加
    func logTaskAdd(goal: Goal, task: GoalTask) {
        addActivityLog(
            goalId: goal.id,
            type: "task_add",
            newValue: task.title,
            message: "添加了任务: \(task.title)"
        )
    }
    
    // 记录任务完成状态变更
    func logTaskCompletion(goal: Goal, task: GoalTask, completed: Bool) {
        addActivityLog(
            goalId: goal.id,
            type: "task_complete",
            oldValue: completed ? "已完成" : "未完成",
            newValue: completed ? "未完成" : "已完成",
            message: "\(completed ? "取消完成" : "完成")了任务: \(task.title)"
        )
    }
    
    // 记录任务删除
    func logTaskRemove(goal: Goal, taskTitle: String) {
        addActivityLog(
            goalId: goal.id,
            type: "task_remove",
            oldValue: taskTitle,
            message: "删除了任务: \(taskTitle)"
        )
    }
    
    // 记录关联联系人添加
    func logContactAdd(goal: Goal, contactId: UUID, contactName: String) {
        addActivityLog(
            goalId: goal.id,
            type: "contact_add",
            newValue: contactName,
            message: "添加了关联联系人: \(contactName)"
        )
    }
    
    // 记录关联联系人删除
    func logContactRemove(goal: Goal, contactId: UUID, contactName: String) {
        addActivityLog(
            goalId: goal.id,
            type: "contact_remove",
            oldValue: contactName,
            message: "删除了关联联系人: \(contactName)"
        )
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
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}