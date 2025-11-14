//
//  GoalDetailView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import UIKit
import Foundation
import SwiftData
import EventKit


struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var allGoals: [Goal]
    @Query private var allContacts: [Contact]
    
    // 观察TagColorManager的变化以实现即时更新
    @ObservedObject private var tagColorManager = TagColorManager.shared
    // 观察PingManager以管理“钉住”状态
    @ObservedObject private var pingManager = PingManager.shared
    
    // 从文档目录加载图片
    private func loadImageFromDocuments(_ imageName: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // 获取应用文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 状态变量
    @State private var selectedDate = Date()
    @State private var showUpperGoalSelector = false
    @State private var showSubGoalSelector = false
    @State private var showDeleteAlert = false
    @State private var showDependencyWarning = false
    @State private var dependencyWarningMessage = ""
    @State private var selectedGoalType = 0
    @State private var showContactSelector = false
    @State private var editingImportance: Int = 1
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    // 防止重复写入当天日记的开场动态
    @State private var didLogHabitOpen = false
    
    // 打卡按钮状态变量
    @State private var isPressed = false
    @State private var isCheckInAnimating = false
    
    // 根据目标名称获取目标对象
    private func getGoalByName(name: String) -> Goal? {
        // 首先尝试通过UUID查找（如果名称是UUID字符串）
        if let uuid = UUID(uuidString: name) {
            let descriptor = FetchDescriptor<Goal>(predicate: #Predicate<Goal> { goal in
                goal.id == uuid
            })
            if let goal = try? modelContext.fetch(descriptor).first {
                return goal
            }
        }
        
        // 如果不是UUID或通过UUID未找到，则通过名称查找
        let descriptor = FetchDescriptor<Goal>(predicate: #Predicate<Goal> { goal in
            goal.name == name
        })
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - 循环引用检测
    
    /// 检查添加目标关系是否会造成循环引用
    /// - Parameters:
    ///   - targetGoalId: 要添加的目标ID
    ///   - relationType: 关系类型（"upper" 或 "sub"）
    ///   - currentGoalId: 当前目标ID
    /// - Returns: 如果会造成循环引用返回true，否则返回false
    private func wouldCreateCycle(adding targetGoalId: String, as relationType: String, to currentGoalId: String) -> Bool {
        // 如果目标ID相同，直接返回true（自引用）
        if targetGoalId == currentGoalId {
            return true
        }
        
        // 获取目标对象
        guard let targetUUID = UUID(uuidString: targetGoalId),
              let targetGoal = allGoals.first(where: { $0.id == targetUUID }) else {
            return false
        }
        
        // 根据关系类型检查循环引用
        if relationType == "upper" {
            // 如果要添加为上级目标，检查该目标的所有上级目标链中是否包含当前目标
            return checkUpwardCycle(from: targetGoalId, target: currentGoalId, visited: Set<String>())
        } else {
            // 如果要添加为子目标，检查该目标的所有子目标链中是否包含当前目标
            return checkDownwardCycle(from: targetGoalId, target: currentGoalId, visited: Set<String>())
        }
    }
    
    /// 向上检查循环引用（检查上级目标链）
    private func checkUpwardCycle(from startGoalId: String, target targetGoalId: String, visited: Set<String>) -> Bool {
        // 如果已经访问过这个目标，说明存在循环
        if visited.contains(startGoalId) {
            return true
        }
        
        // 如果找到目标，说明存在循环引用
        if startGoalId == targetGoalId {
            return true
        }
        
        // 获取当前目标
        guard let startUUID = UUID(uuidString: startGoalId),
              let startGoal = allGoals.first(where: { $0.id == startUUID }) else {
            return false
        }
        
        // 将当前目标添加到已访问集合
        var newVisited = visited
        newVisited.insert(startGoalId)
        
        // 递归检查所有上级目标
        for upperProjectId in startGoal.upperProject {
            if checkUpwardCycle(from: upperProjectId, target: targetGoalId, visited: newVisited) {
                return true
            }
        }
        
        return false
    }
    
    /// 向下检查循环引用（检查子目标链）
    private func checkDownwardCycle(from startGoalId: String, target targetGoalId: String, visited: Set<String>) -> Bool {
        // 如果已经访问过这个目标，说明存在循环
        if visited.contains(startGoalId) {
            return true
        }
        
        // 如果找到目标，说明存在循环引用
        if startGoalId == targetGoalId {
            return true
        }
        
        // 获取当前目标
        guard let startUUID = UUID(uuidString: startGoalId),
              let startGoal = allGoals.first(where: { $0.id == startUUID }) else {
            return false
        }
        
        // 将当前目标添加到已访问集合
        var newVisited = visited
        newVisited.insert(startGoalId)
        
        // 递归检查所有子目标
        for subProjectId in startGoal.subProject {
            if checkDownwardCycle(from: subProjectId, target: targetGoalId, visited: newVisited) {
                return true
            }
        }
        
        return false
    }
    @State private var selectedBackgroundImage: String? = nil
    
    // 常量
    private let goalTypes = ["人生目标", "年度目标", "短期目标", "习惯"]
    private let backgroundImages = [
        "GoalGradientBlue",
        "GoalGradientGreen",
        "GoalGradientOrange",
        "GoalGradientPink",
        "GoalGradientBlack",
        "GoalGradientRed",
        nil
    ]
    private var availableUpperGoals: [String] {
        // 过滤掉当前目标、已经是子目标的目标、回收站中的目标、以及会造成循环引用的目标
        allGoals.filter { otherGoal in
            let otherGoalId = otherGoal.id.uuidString
            let currentGoalId = goal.id.uuidString
            
            // 排除当前目标
            if otherGoal.id == goal.id { return false }
            
            // 排除已经是当前目标的子目标的目标（防止循环引用）
            if goal.subProject.contains(otherGoalId) { return false }
            
            // 排除已经将当前目标作为上级目标的目标（防止重复关系）
            if otherGoal.upperProject.contains(currentGoalId) { return false }
            
            // 排除回收站中的目标
            if otherGoal.isDeleted { return false }
            
            // 递归检查是否会造成循环引用
            return !wouldCreateCycle(adding: otherGoalId, as: "upper", to: currentGoalId)
        }.map { $0.id.uuidString }
    }
    
    private var availableSubGoals: [String] { 
        // 过滤掉当前目标、已经是上级目标的目标、回收站中的目标、以及会造成循环引用的目标
        allGoals.filter { otherGoal in
            let otherGoalId = otherGoal.id.uuidString
            let currentGoalId = goal.id.uuidString
            
            // 排除当前目标
            if otherGoal.id == goal.id { return false }
            
            // 排除已经是当前目标的上级目标的目标（防止循环引用）
            if goal.upperProject.contains(otherGoalId) { return false }
            
            // 排除已经将当前目标作为子目标的目标（防止重复关系）
            if otherGoal.subProject.contains(currentGoalId) { return false }
            
            // 排除回收站中的目标
            if otherGoal.isDeleted { return false }
            
            // 递归检查是否会造成循环引用
            return !wouldCreateCycle(adding: otherGoalId, as: "sub", to: currentGoalId)
        }.map { $0.id.uuidString }
    }
    
    // 目标对象
    @State var goal: Goal
    
    // 状态变量
    @State private var showEditSheet = false
    @State private var showAddTaskSheet = false
    @State private var editingField: EditableField? = nil
    @State private var editingValue: String = ""
    @State private var editingProgress: Double = 0
    @State private var editingTask: GoalTask? = nil
    @State private var showActivityLog = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddTagSheet = false
    
    // 可编辑字段枚举
    enum EditableField {
        case name
        case goalDescription
        case progress
        case tag
        case upperProject
        case subProject
        case task
        case dueDate
        case backgroundImage
        case none
    }
    
    // 为标签生成颜色 - 使用TagColorManager
    private func tagColor(for tag: String) -> Color {
        return tagColorManager.getColor(for: tag)
    }
    
    // 计算属性
    
    // 截止日期视图
    private var dueDateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .frame(width: 24, height: 24)
                
                Text("截止日期")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { goal.dueDate != nil },
                    set: { hasDate in
                        if hasDate {
                            // 如果开启，设置为当前日期
                            let oldDueDate = goal.dueDate
                            goal.dueDate = Date()
                            goal.modifyTime = Date()
                            
                            // 记录截止日期修改
                            GoalActivityManager.shared.logDueDateChange(goal: goal, oldDueDate: oldDueDate, modelContext: modelContext)
                            
                            do {
                                try modelContext.save()
                            } catch {
                                print("Failed to save due date: \(error)")
                            }
                        } else {
                            // 如果关闭，清除截止日期
                            let oldDueDate = goal.dueDate
                            goal.dueDate = nil
                            goal.modifyTime = Date()
                            
                            // 记录截止日期修改
                            GoalActivityManager.shared.logDueDateChange(goal: goal, oldDueDate: oldDueDate, modelContext: modelContext)
                            
                            do {
                                try modelContext.save()
                            } catch {
                                print("Failed to save due date: \(error)")
                            }
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
            }
            
            // 如果有截止日期，显示日期选择器
            if goal.dueDate != nil {
                DatePicker("", selection: Binding(
                    get: { goal.dueDate ?? Date() },
                    set: { newDate in
                        let oldDueDate = goal.dueDate
                        goal.dueDate = newDate
                        goal.modifyTime = Date()
                        
                        // 记录截止日期修改
                        GoalActivityManager.shared.logDueDateChange(goal: goal, oldDueDate: oldDueDate, modelContext: modelContext)
                        
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save due date: \(error)")
                        }
                    }
                ), displayedComponents: [.date])
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.leading, 32) // 与图标和文字对齐
            }
        }
        .padding(.horizontal, 16)
    }
    
    // 子任务视图
    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .frame(width: 24, height: 24)
                
                Text("子任务")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                // 添加任务按钮
                Button(action: {
                    showAddTaskSheet = true
                }) {
                    HStack(spacing: 4) {
                        Text("添加")
                            .font(.system(size: 14))
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            
            if goal.tasks.isEmpty {
                Text("暂无子任务")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
            } else {
                List {
                    ForEach(goal.tasks) { task in
                        HStack(spacing: 12) {
                            Button(action: {
                                let wasDone = task.isCompleted
                                switch task.status {
                                case .todo:
                                    task.status = .inProgress
                                case .inProgress:
                                    task.status = .done
                                case .done:
                                    task.status = .todo
                                }
                                task.isCompleted = (task.status == .done)
                                goal.modifyTime = Date()
                                if wasDone != task.isCompleted {
                                    GoalActivityManager.shared.logTaskCompletion(goal: goal, task: task, completed: wasDone, modelContext: modelContext)
                                }
                                do { try modelContext.save() } catch { print("Failed to save task update: \(error)") }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke((task.status == .done || task.status == .inProgress) ? Color.clear : Color(UIColor.systemGray3), lineWidth: 1.5)
                                        .frame(width: 22, height: 22)
                                    if task.status == .done {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 22, height: 22)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if task.status == .inProgress {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 22, height: 22)
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 任务名称
                            Text(task.title)
                                .font(.system(size: 15))
                                .foregroundColor(task.status == .done ? Color(UIColor.systemGray) : Color(UIColor.label))
                                .strikethrough(task.status == .done)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onTapGesture {
                                    editingField = .task
                                    editingTask = task
                                    editingValue = task.title
                                    showEditSheet = true
                                }
                        }
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .onDelete(perform: deleteTask)
                    .onMove(perform: moveTask)
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, .constant(.active))
                // 使用insetGrouped样式使拖动指示器更加明显
                .padding(.horizontal, 16)
                // 移除固定高度限制，允许列表自然扩展
            }
        }
    }
    
    // 上级目标和子目标视图
    private var projectsView: some View {
        VStack(spacing: 20) {
            // 上级目标
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("上级目标")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.label))
                    
                    Spacer()
                    
                    // 添加上级目标按钮
                    Button(action: {
                        showUpperGoalSelector = true
                    }) {
                        HStack(spacing: 4) {
                            Text("添加")
                                .font(.system(size: 14))
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                
                if goal.upperProject.isEmpty {
                    Text("暂无上级目标")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 10) {
                        ForEach(goal.upperProject, id: \.self) { project in
                            HStack {
                                // 目标图标
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .frame(width: 24, height: 24)
                                
                                // 目标名称 - 添加导航链接
                                NavigationLink(destination: Group {
                                    if let uuid = UUID(uuidString: project),
                                       let targetGoal = allGoals.first(where: { $0.id == uuid }) {
                                        GoalDetailView(goal: targetGoal)
                                    } else {
                                        Text("目标不存在")
                                    }
                                }) {
                                    if let uuid = UUID(uuidString: project),
                                       let targetGoal = allGoals.first(where: { $0.id == uuid }) {
                                        Text(targetGoal.name)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(UIColor.label))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        Text("未知目标")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                
                                // 删除按钮
                                Button(action: {
                                    // 删除上级目标
                                    if let index = goal.upperProject.firstIndex(of: project) {
                                        goal.upperProject.remove(at: index)
                                        // 更新修改时间
                                        goal.modifyTime = Date()
                                        
                                        // 同时从上级目标的子目标列表中移除当前目标
                                        if let uuid = UUID(uuidString: project),
                                           let upperGoal = allGoals.first(where: { $0.id == uuid }) {
                                            let currentGoalId = goal.id.uuidString
                                            if let subIndex = upperGoal.subProject.firstIndex(of: currentGoalId) {
                                                upperGoal.subProject.remove(at: subIndex)
                                                upperGoal.modifyTime = Date()
                                                
                                                // 记录上级目标删除
                                                GoalActivityManager.shared.logUpperProjectRemove(goal: goal, upperProject: upperGoal.name, modelContext: modelContext)
                                            }
                                        }
                                        
                                        // 保存更改
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to save upper project deletion: \(error)")
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(UIColor.systemGray3))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // 单独添加上级目标的逻辑（确保双向同步）
                .onChange(of: goal.upperProject, initial: false) { oldUpperProjects, newUpperProjects in
                    let oldSet = Set(oldUpperProjects)
                    let newSet = Set(newUpperProjects)
                    let added = newSet.subtracting(oldSet)
                    let removed = oldSet.subtracting(newSet)
                    let currentGoalId = goal.id.uuidString
                    // 新增上级目标时，自动同步到对应目标的subProject
                    for upperId in added {
                        if let uuid = UUID(uuidString: upperId),
                           let upperGoal = allGoals.first(where: { $0.id == uuid }) {
                            if !upperGoal.subProject.contains(currentGoalId) {
                                upperGoal.subProject.append(currentGoalId)
                                upperGoal.modifyTime = Date()
                                // 记录上级目标添加
                                GoalActivityManager.shared.logUpperProjectAdd(goal: goal, upperProject: upperGoal.name, modelContext: modelContext)
                            }
                        }
                    }
                    // 移除上级目标时，自动同步到对应目标的subProject
                    for upperId in removed {
                        if let uuid = UUID(uuidString: upperId),
                           let upperGoal = allGoals.first(where: { $0.id == uuid }) {
                            if let idx = upperGoal.subProject.firstIndex(of: currentGoalId) {
                                upperGoal.subProject.remove(at: idx)
                                upperGoal.modifyTime = Date()
                                // 记录上级目标删除
                                GoalActivityManager.shared.logUpperProjectRemove(goal: goal, upperProject: upperGoal.name, modelContext: modelContext)
                            }
                        }
                    }
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to sync upperProject add/remove: \(error)")
                    }
                }
                // 子目标
                VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("子目标")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.label))
                    
                    Spacer()
                    
                    // 添加子目标按钮
                    Button(action: {
                        showSubGoalSelector = true
                    }) {

                        HStack(spacing: 4) {
                            Text("添加")
                                .font(.system(size: 14))
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                
                // 单独添加子目标的逻辑（确保双向同步）
                .onChange(of: goal.subProject, initial: false) { oldSubProjects, newSubProjects in
                    let oldSet = Set(oldSubProjects)
                    let newSet = Set(newSubProjects)
                    let added = newSet.subtracting(oldSet)
                    let removed = oldSet.subtracting(newSet)
                    let currentGoalId = goal.id.uuidString
                    // 新增子目标时，自动同步到对应目标的upperProject
                    for subId in added {
                        if let uuid = UUID(uuidString: subId),
                           let subGoal = allGoals.first(where: { $0.id == uuid }) {
                            if !subGoal.upperProject.contains(currentGoalId) {
                                subGoal.upperProject.append(currentGoalId)
                                subGoal.modifyTime = Date()
                                // 记录子目标添加
                                GoalActivityManager.shared.logSubProjectAdd(goal: goal, subProject: subGoal.name, modelContext: modelContext)
                            }
                        }
                    }
                    // 移除子目标时，自动同步到对应目标的upperProject
                    for subId in removed {
                        if let uuid = UUID(uuidString: subId),
                           let subGoal = allGoals.first(where: { $0.id == uuid }) {
                            if let idx = subGoal.upperProject.firstIndex(of: currentGoalId) {
                                subGoal.upperProject.remove(at: idx)
                                subGoal.modifyTime = Date()
                                // 记录子目标删除
                                GoalActivityManager.shared.logSubProjectRemove(goal: goal, subProject: subGoal.name, modelContext: modelContext)
                            }
                        }
                    }
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to sync subProject add/remove: \(error)")
                    }
                }
                if goal.subProject.isEmpty {
                    Text("暂无子目标")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 10) {
                        ForEach(goal.subProject, id: \.self) { project in
                            HStack {
                                // 目标图标
                                Image(systemName: "arrow.down.forward")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.systemGreen))
                                    .frame(width: 24, height: 24)
                                
                                // 目标名称 - 添加导航链接
                                NavigationLink(destination: Group {
                                    if let uuid = UUID(uuidString: project),
                                       let targetGoal = allGoals.first(where: { $0.id == uuid }) {
                                        GoalDetailView(goal: targetGoal)
                                    } else {
                                        Text("目标不存在")
                                    }
                                }) {
                                    if let uuid = UUID(uuidString: project),
                                       let targetGoal = allGoals.first(where: { $0.id == uuid }) {
                                        Text(targetGoal.name)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(UIColor.label))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        Text("未知目标")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                
                                // 删除按钮
                                Button(action: {
                                    // 删除子目标
                                    if let index = goal.subProject.firstIndex(of: project) {
                                        goal.subProject.remove(at: index)
                                        // 更新修改时间
                                        goal.modifyTime = Date()
                                        
                                        // 同时从子目标的上级目标列表中移除当前目标
                                        if let uuid = UUID(uuidString: project),
                                           let subGoal = allGoals.first(where: { $0.id == uuid }) {
                                            let currentGoalId = goal.id.uuidString
                                            if let upperIndex = subGoal.upperProject.firstIndex(of: currentGoalId) {
                                                subGoal.upperProject.remove(at: upperIndex)
                                                subGoal.modifyTime = Date()
                                                
                                                // 记录子目标删除
                                                GoalActivityManager.shared.logSubProjectRemove(goal: goal, subProject: subGoal.name, modelContext: modelContext)
                                            }
                                        }
                                        
                                        // 保存更改
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to save sub project deletion: \(error)")
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(UIColor.systemGray3))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    private var formattedCreateDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: goal.createTime)
    }
    
    private var formattedDueDate: String {
        guard let dueDate = goal.dueDate else { return "未设置" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: dueDate)
    }
    
    // 目标类型选择状态
    @State private var showGoalTypeMenu = false
    // 优先级选择状态
    // 注释掉重复声明的变量，因为已经在前面第26行声明过了
    // @State private var editingImportance: Int = 1
    
    // 初始化方法
    init(goal: Goal) {
        _goal = State(initialValue: goal)
        // 根据goal.goalType初始化selectedGoalType
        let initialGoalType: Int
        switch goal.goalType {
        case .life:
            initialGoalType = 0
        case .yearly:
            initialGoalType = 1
        case .shortTerm:
            initialGoalType = 2
        case .habit:
            initialGoalType = 3
        }
        _selectedGoalType = State(initialValue: initialGoalType)
        // 初始化优先级
        _editingImportance = State(initialValue: goal.importance)
    }
    
    // 处理保存目标编辑
    private func handleSaveGoalEdit(field: EditableField?, value: String, progress: Double) {
        guard let field = field else { return }
        
        switch field {
        case .name:
            let oldName = goal.name
            goal.name = value
            // 记录名称修改到活动日志和当天日记
            GoalActivityManager.shared.logNameChange(goal: goal, oldName: oldName, modelContext: modelContext)
        case .goalDescription:
            let oldDescription = goal.goalDescription
            goal.goalDescription = value
            // 记录描述修改到活动日志和当天日记
            GoalActivityManager.shared.logDescriptionChange(goal: goal, oldDescription: oldDescription, modelContext: modelContext)
        case .progress:
            let oldProgress = goal.progress
            goal.progress = progress
            // 记录进度修改到活动日志和当天日记
            GoalActivityManager.shared.logProgressChange(goal: goal, oldProgress: oldProgress, modelContext: modelContext)
        case .tag:
            if !value.isEmpty {
                // 添加新标签
                if !goal.tags.contains(value) {
                    goal.tags.append(value)
                    // 记录标签添加到活动日志和当天日记
                    GoalActivityManager.shared.logTagAdd(goal: goal, tag: value, modelContext: modelContext)
                }
            }
        case .task:
            if let task = editingTask {
                let oldTitle = task.title
                task.title = value
                // 记录任务修改到活动日志和当天日记
                GoalActivityManager.shared.logTaskModify(goal: goal, oldTitle: oldTitle, newTitle: value, modelContext: modelContext)
            }
        case .upperProject, .subProject, .dueDate, .none:
            // 这些字段在其他地方处理
            break
        @unknown default:
            // 处理未来可能添加的枚举值
            print("未知的编辑字段类型")
            break
        }
        
        // 更新修改时间
        goal.modifyTime = Date()
        
        // 保存修改
        do {
            try modelContext.save()
        } catch {
            print("Failed to save goal edit: \(error)")
        }
    }
    
    // 此方法已被移除，因为 DatePickerView 直接使用 modelContext 保存数据
    
    // 此方法已被移除，因为 AddTaskView 直接使用 modelContext 保存数据
    
    // 此方法已被移除，因为 GoalSelectorView 直接使用 modelContext 保存数据
    
    // 保存目标的所有修改
    private func saveGoal() -> Void {
        // 记录目标类型修改
        let oldGoalType = goal.goalType
        
        // 根据selectedGoalType更新goal.goalType
        var newGoalType: GoalType = .shortTerm
        switch selectedGoalType {
        case 0:
            newGoalType = .life
        case 1:
            newGoalType = .yearly
        case 2:
            newGoalType = .shortTerm
        case 3:
            newGoalType = .habit
        default:
            break
        }
        
        // 如果类型有变化，记录日志
        if oldGoalType != newGoalType {
            goal.goalType = newGoalType
            GoalActivityManager.shared.logTypeChange(goal: goal, oldType: oldGoalType, modelContext: modelContext)
        }
        
        // 更新修改时间
        goal.modifyTime = Date()
        
        do {
            try modelContext.save()
            
            // 显示保存成功提示
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // 返回上一个视图
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save goal: \(error)")
        }
    }
    
    // 检查目标是否被其他目标关联
    private func checkGoalDependencies() -> (hasUpperGoals: Bool, hasSubGoals: Bool, upperGoalNames: [String], subGoalNames: [String]) {
        let goalId = goal.id.uuidString
        var upperGoalNames: [String] = []
        var subGoalNames: [String] = []
        
        // 查询所有目标
        let allGoals = try? modelContext.fetch(FetchDescriptor<Goal>())
        
        for otherGoal in allGoals ?? [] {
            // 跳过当前目标
            if otherGoal.id == goal.id { continue }
            
            // 检查是否有其他目标将当前目标作为上级目标
            if otherGoal.upperProject.contains(goalId) {
                upperGoalNames.append(otherGoal.name)
            }
            
            // 检查是否有其他目标将当前目标作为子目标
            if otherGoal.subProject.contains(goalId) {
                subGoalNames.append(otherGoal.name)
            }
        }
        
        return (hasUpperGoals: !upperGoalNames.isEmpty, hasSubGoals: !subGoalNames.isEmpty, upperGoalNames: upperGoalNames, subGoalNames: subGoalNames)
    }
    
    // 获取用户设置的回收站过期天数
    private func getTrashExpirationDays() -> Int {
        return TrashCleanupService.shared.getUserTrashExpirationDays(modelContext: modelContext)
    }
    
    // 删除目标（移到回收站）
    private func deleteGoal() {
        // 检查目标依赖关系
        let dependencies = checkGoalDependencies()
        
        // 如果有关联目标，显示警告并阻止删除
        if dependencies.hasUpperGoals || dependencies.hasSubGoals {
            var warningMessage = "无法删除目标 \"\(goal.name)\"，因为它被以下目标关联：\n\n"
            
            if dependencies.hasUpperGoals {
                warningMessage += "作为上级目标被关联：\n"
                for name in dependencies.upperGoalNames {
                    warningMessage += "• \(name)\n"
                }
                warningMessage += "\n"
            }
            
            if dependencies.hasSubGoals {
                warningMessage += "作为子目标被关联：\n"
                for name in dependencies.subGoalNames {
                    warningMessage += "• \(name)\n"
                }
                warningMessage += "\n"
            }
            
            warningMessage += "请先在相关目标中解除关联，然后再删除此目标。"
            
            // 显示警告对话框
            showDependencyWarning = true
            dependencyWarningMessage = warningMessage
            return
        }
        
        // 如果没有关联，将目标移到回收站（软删除）
        goal.moveToTrash()
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("移动目标到回收站失败: \(error)")
        }
        
        // 返回上一个视图
        presentationMode.wrappedValue.dismiss()
    }
    
    // 处理打卡操作
    private func handleCheckIn() {
        // 触发打卡动画
        isCheckInAnimating = true
        
        // 记录打卡活动到日志
        GoalActivityManager.shared.addActivityLogWithDiary(
            goalId: goal.id,
            goalName: goal.name,
            type: "habit_checkin",
            message: "完成了习惯打卡",
            modelContext: modelContext
        )
        
        // 可选：增加目标进度（根据需求决定是否启用）
        // let oldProgress = goal.progress
        // goal.progress = min(goal.progress + 0.01, 1.0) // 增加1%进度
        // GoalActivityManager.shared.logProgressChange(goal: goal, oldProgress: oldProgress, modelContext: modelContext)
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("保存打卡记录失败: \(error)")
        }
        
        // 提供触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // 删除任务
    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let taskToDelete = goal.tasks[index]
            // 记录任务删除
            GoalActivityManager.shared.logTaskRemove(goal: goal, taskTitle: taskToDelete.title)
            modelContext.delete(taskToDelete)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete task: \(error)")
        }
    }
    
    // 移动任务（拖动排序）
    private func moveTask(from source: IndexSet, to destination: Int) {
        // 使用SwiftUI内置的数组移动方法
        goal.tasks.move(fromOffsets: source, toOffset: destination)
        goal.modifyTime = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to move task: \(error)")
        }
    }
    
    // headerView部分插入优先级选择器
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("优先级")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Picker("优先级", selection: $editingImportance) {
                    Text("低").tag(1)
                    Text("中").tag(2)
                    Text("高").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)
                .onChange(of: editingImportance) { oldValue, newValue in
                    let oldImportance = goal.importance
                    goal.importance = newValue
                    goal.modifyTime = Date()
                    
                    // 记录重要性修改
                    GoalActivityManager.shared.logImportanceChange(goal: goal, oldImportance: oldImportance)
                    
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to save importance: \(error)")
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .padding(.bottom, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    // 标签视图
    var goalTagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(goal.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .foregroundColor(.white)
                                
                                // 删除标签按钮
                                Button(action: {
                                    // 删除标签
                                    if let index = goal.tags.firstIndex(of: tag) {
                                        goal.tags.remove(at: index)
                                        // 更新修改时间
                                        goal.modifyTime = Date()
                                        // 记录标签删除
                                        GoalActivityManager.shared.logTagRemove(goal: goal, tag: tag)
                                        // 保存更改
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to save tag deletion: \(error)")
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(tagColor(for: tag))
                            .cornerRadius(12)
                }
                
                // 添加标签按钮
                Button(action: {
                    showAddTagSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 24, height: 24)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .frame(height: 40)
    }
    
    // 目标名称和进度视图
    var goalNameProgressView: some View {
        HStack {
            if editingField == .name {
                TextField(
                    "目标名称",
                    text: $editingValue,
                    onCommit: {
                        // 保存修改
                        let oldName = goal.name
                        goal.name = editingValue
                        goal.modifyTime = Date()
                        try? modelContext.save()
                        
                        // 记录活动
                        GoalActivityManager.shared.logNameChange(goal: goal, oldName: oldName, modelContext: modelContext)
                        
                        // 退出编辑模式
                        editingField = nil
                    }
                )
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(UIColor.label))
                .onAppear {
                    // 自动聚焦
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            } else {
                Text(goal.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                    .onTapGesture {
                        editingField = .name
                        editingValue = goal.name
                    }
            }

            // “钉子”按钮：钉住/取消钉住当前目标
            Button(action: {
                if pingManager.isPinged(goalID: goal.id) {
                pingManager.unping(goalID: goal.id)
            } else {
                pingManager.ping(goalID: goal.id)
            }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: pingManager.isPinged(goalID: goal.id) ? "pin.slash.fill" : "pin.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(pingManager.isPinged(goalID: goal.id) ? "取消Ping" : "Ping到主页")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(Color(UIColor.systemBlue))
                .background(Color(UIColor.systemBlue).opacity(0.12))
                .clipShape(Capsule())
                .accessibilityLabel(pingManager.isPinged(goalID: goal.id) ? "取消钉住" : "钉住")
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
            progressRingView
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // 进度环形指示器
    var progressRingView: some View {
        Button(action: {
            editingField = .progress
            editingProgress = goal.progress
            showEditSheet = true
        }) {
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 6)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: CGFloat(goal.progress))
                    .stroke(
                        goal.progress > 0.7 ? Color(UIColor.systemGreen) : (goal.progress > 0.3 ? Color(UIColor.systemOrange) : Color(UIColor.systemRed)),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(goal.progress * 100))%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 页面出现时记录习惯打开日志，拆分以降低类型检查复杂度
    private func logHabitOpenIfNeeded() {
        if goal.goalType == .habit && !didLogHabitOpen {
            GoalActivityManager.shared.addActivityLogWithDiary(
                goalId: goal.id,
                goalName: goal.name,
                type: "habit_open",
                message: "查看了习惯目标",
                modelContext: modelContext
            )
            didLogHabitOpen = true
        }
    }

    // 进度条区域，拆分以降低类型检查复杂度
    private var progressBarSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("进度")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Button(action: {
                    editingField = .progress
                    editingProgress = goal.progress
                    showEditSheet = true
                }) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemBlue))
                }
                .buttonStyle(PlainButtonStyle())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 8)

                    // 进度条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemBlue))
                        .frame(width: max(4, geometry.size.width * CGFloat(goal.progress)), height: 8)
                        .animation(.easeOut(duration: 0.3), value: goal.progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 16)
    }
    
    // 目标类型菜单视图
    var goalTypeMenuView: some View {
        Menu {
            ForEach(0..<goalTypes.count, id: \.self) { index in
                Button(action: {
                    // 只更新selectedGoalType，不直接修改goal对象
                    // 这样可以避免SwiftData自动保存导致页面跳转
                    selectedGoalType = index
                }) {
                    Text(goalTypes[index])
                }
            }
        } label: {
            HStack {
                Text(goalTypes[selectedGoalType])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.systemBlue))
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.systemBlue))
            }
            .padding(.horizontal, 16)
        }
    }
    
    // 目标描述视图
    var goalDescriptionView: some View {
        VStack(alignment: .leading) {
            if editingField == .goalDescription {
                TextEditor(text: $editingValue)
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.darkGray))
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)))
                    .onAppear {
                        // 自动聚焦
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                
                HStack {
                    Spacer()
                    Button("完成") {
                        // 保存修改
                        let oldDescription = goal.goalDescription
                        goal.goalDescription = editingValue
                        goal.modifyTime = Date()
                        try? modelContext.save()
                        
                        // 记录活动
                        GoalActivityManager.shared.logDescriptionChange(goal: goal, oldDescription: oldDescription, modelContext: modelContext)
                        
                        // 退出编辑模式
                        editingField = nil
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 4)
            } else {
                Text(goal.goalDescription)
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        editingField = .goalDescription
                        editingValue = goal.goalDescription
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 保存当前编辑的内容
    private func saveCurrentEditing() {
        guard let field = editingField else { return }
        
        switch field {
        case .name:
            let oldName = goal.name
            if !editingValue.isEmpty {
                goal.name = editingValue
                goal.modifyTime = Date()
                try? modelContext.save()
                GoalActivityManager.shared.logNameChange(goal: goal, oldName: oldName, modelContext: modelContext)
            }
            
        case .goalDescription:
            let oldDescription = goal.goalDescription
            goal.goalDescription = editingValue
            goal.modifyTime = Date()
            try? modelContext.save()
            GoalActivityManager.shared.logDescriptionChange(goal: goal, oldDescription: oldDescription, modelContext: modelContext)
            
        default:
            break
        }
        
        // 退出编辑模式
        editingField = nil
    }
    
    // 顶部钉住按钮视图，拆分以降低类型检查复杂度
    private var pinButtonView: some View {
        let isPinned = pingManager.isPinged(goalID: goal.id)
        return Button(action: {
            if isPinned {
                pingManager.unping(goalID: goal.id)
            } else {
                pingManager.ping(goalID: goal.id)
            }
        }) {
            Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(UIColor.systemBlue))
                .frame(width: 32, height: 32)
                .background(Color(UIColor.systemBlue).opacity(0.12))
                .clipShape(Circle())
                .accessibilityLabel(Text(isPinned ? "取消钉住" : "钉住"))
        }
    }

    // 目标名称区域内容，拆分以降低类型检查复杂度
    private var goalNameHeaderContent: some View {
        HStack {
            if editingField == .name {
                TextField(
                    "目标名称",
                    text: $editingValue,
                    onCommit: {
                        let oldName = goal.name
                        if !editingValue.isEmpty {
                            goal.name = editingValue
                            goal.modifyTime = Date()
                            try? modelContext.save()
                            GoalActivityManager.shared.logNameChange(goal: goal, oldName: oldName, modelContext: modelContext)
                        }
                        editingField = nil
                    }
                )
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(UIColor.label))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            } else {
                Text(goal.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                    .onTapGesture {
                        editingField = .name
                        editingValue = goal.name
                    }
            }
            Spacer()
        }
    }

    // 目标类型选择区域，拆分以降低类型检查复杂度
    private var goalTypeSection: some View {
        HStack {
            Image(systemName: "tag")
                .font(.system(size: 16))
                .foregroundColor(Color(UIColor.systemBlue))
                .frame(width: 24, height: 24)

            Text("目标类型")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(UIColor.label))

            Spacer()

            Menu {
                ForEach(0..<goalTypes.count, id: \.self) { index in
                    Button(action: {
                        // 只更新selectedGoalType，不直接修改goal对象
                        // 这样可以避免SwiftData自动保存导致页面跳转
                        selectedGoalType = index
                    }) {
                        Text(goalTypes[index])
                    }
                }
            } label: {
                Text(goalTypes[selectedGoalType])
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(15)
            }
        }
        .padding(.horizontal, 16)
    }

    // 标签区域，拆分以降低类型检查复杂度
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .frame(width: 24, height: 24)

                Text("标签")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))

                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(goal.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .foregroundColor(.white)

                            // 删除标签按钮
                            Button(action: {
                                // 删除标签
                                if let index = goal.tags.firstIndex(of: tag) {
                                    goal.tags.remove(at: index)
                                    // 更新修改时间
                                    goal.modifyTime = Date()
                                    // 记录标签删除
                                    GoalActivityManager.shared.logTagRemove(goal: goal, tag: tag)
                                    // 保存更改
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("Failed to save tag deletion: \(error)")
                                    }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(tagColor(for: tag))
                        .cornerRadius(12)
                    }

                    // 添加标签按钮（使用可复用的 AddTagSheet）
                    Button(action: {
                        showAddTagSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .frame(width: 24, height: 24)
                            .background(Color(UIColor.systemBlue).opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
            }
            .frame(height: 40)
        }
    }

    private func taskRow(_ task: GoalTask) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                let wasDone = task.isCompleted
                switch task.status {
                case .todo: task.status = .inProgress
                case .inProgress: task.status = .done
                case .done: task.status = .todo
                }
                task.isCompleted = (task.status == .done)
                goal.modifyTime = Date()
                if wasDone != task.isCompleted {
                    GoalActivityManager.shared.logTaskCompletion(goal: goal, task: task, completed: wasDone)
                }
                do { try modelContext.save() } catch { print("Failed to save task update: \(error)") }
            }) {
                ZStack {
                    Circle()
                        .stroke((task.status == .done || task.status == .inProgress) ? Color.clear : Color(UIColor.systemGray3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if task.status == .done {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    } else if task.status == .inProgress {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 22, height: 22)
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            Text(task.title)
                .font(.system(size: 16))
                .foregroundColor(task.status == .done ? Color(UIColor.systemGray) : Color(UIColor.label))
                .strikethrough(task.status == .done)
                .onTapGesture {
                    editingField = .task
                    editingTask = task
                    editingValue = task.title
                    showEditSheet = true
                }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var overviewCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .trailing) {
                pinButtonView
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .zIndex(1)
                goalNameHeaderContent
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            progressBarSection
            goalTypeSection
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .frame(width: 24, height: 24)
                Text("目标描述")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            .padding(.horizontal, 16)
            goalDescriptionView
            HStack {
                Image(systemName: "flag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemRed))
                    .frame(width: 24, height: 24)
                Text("优先级")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Picker("优先级", selection: $editingImportance) {
                    Text("低").tag(1)
                    Text("中").tag(2)
                    Text("高").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)
                .onChange(of: editingImportance) { oldValue, newValue in
                    let oldImportance = goal.importance
                    goal.importance = newValue
                    goal.modifyTime = Date()
                    GoalActivityManager.shared.logImportanceChange(goal: goal, oldImportance: oldImportance)
                    do { try modelContext.save() } catch { print("Failed to save importance: \(error)") }
                }
            }
            .padding(.horizontal, 16)
            dueDateView
            tagsSection
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var projectRelationsCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemBlue))
                Text("目标关联")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            .padding(.horizontal, 16)
            projectsView
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var subTasksCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemBlue))
                Text("子任务")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            .padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 12) {
                if goal.tasks.isEmpty {
                    Text("暂无子任务")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                } else {
                    List {
                        ForEach(goal.tasks) { task in
                            taskRow(task)
                        }
                        .onDelete(perform: deleteTask)
                    }
                    .listStyle(.plain)
                    .frame(height: CGFloat(goal.tasks.count) * 70)
                }
                Button(action: { showAddTaskSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("添加任务")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var relatedContactsCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemBlue))
                Text("关联人")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Button(action: { showContactSelector = true }) {
                    Text("选择")
                        .font(.system(size: 15))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 8) {
                if goal.relatedContactIds.isEmpty {
                    Text("未关联联系人")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(goal.relatedContactIds, id: \.self) { id in
                                if let contact = allContacts.first(where: { $0.id == id }) {
                                    HStack(spacing: 4) {
                                        Text(contact.name)
                                            .foregroundColor(Color(UIColor.systemBlue))
                                        Button(action: {
                                            if let idx = goal.relatedContactIds.firstIndex(of: id) {
                                                goal.relatedContactIds.remove(at: idx)
                                                goal.modifyTime = Date()
                                                if let contact = allContacts.first(where: { $0.id == id }) {
                                                    var contactGoalIds = contact.relatedGoalIds
                                                    if let goalIdx = contactGoalIds.firstIndex(of: goal.id) {
                                                        contactGoalIds.remove(at: goalIdx)
                                                        contact.relatedGoalIds = contactGoalIds
                                                        GoalActivityManager.shared.logContactRemove(goal: goal, contactId: id, contactName: contact.name)
                                                    }
                                                }
                                                do { try modelContext.save() } catch { print("Failed to save contact unlink: \(error)") }
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(UIColor.systemGray3))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(UIColor.systemBlue).opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                    }
                    .frame(height: 40)
                }
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var backgroundImageCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemBlue))
                Text("背景图片")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Button(action: {
                    editingField = .backgroundImage
                    selectedBackgroundImage = goal.backgroundImage
                    showImagePicker = true
                }) {
                    Text("选择")
                        .font(.system(size: 15))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            goal.backgroundImage = nil
                            goal.modifyTime = Date()
                            do { try modelContext.save() } catch { print("Failed to save background image: \(error)") }
                        }) {
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(width: 80, height: 60)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(goal.backgroundImage == nil ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                Text("默认")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        let userUploadedImages = UserDefaults.standard.stringArray(forKey: "UserUploadedImages") ?? []
                        let hiddenImages = UserDefaults.standard.stringArray(forKey: "UserHiddenImages") ?? []
                        let visibleUserImages = userUploadedImages.filter { !hiddenImages.contains($0) }
                        ForEach(visibleUserImages, id: \.self) { imageName in
                            Button(action: {
                                goal.backgroundImage = imageName
                                goal.modifyTime = Date()
                                do { try modelContext.save() } catch { print("Failed to save background image: \(error)") }
                            }) {
                                if let uiImage = loadImageFromDocuments(imageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 60)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(goal.backgroundImage == imageName ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        ForEach(backgroundImages.compactMap { $0 }, id: \.self) { imageName in
                            Button(action: {
                                goal.backgroundImage = imageName
                                goal.modifyTime = Date()
                                do { try modelContext.save() } catch { print("Failed to save background image: \(error)") }
                            }) {
                                if let uiImage = UIImage(named: imageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 60)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(goal.backgroundImage == imageName ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                }
                .frame(height: 70)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var bottomButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: { showActivityLog = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                    Text("查看动态")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            Button(action: { showDeleteAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                    Text("删除目标")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 不影响布局的钩子：页面首次出现时写入当天日记动态（仅限习惯目标）
                EmptyView()
                    .onAppear {
                        logHabitOpenIfNeeded()
                    }
                overviewCardView
                
                projectRelationsCardView
                
                subTasksCardView
                
                relatedContactsCardView
                
                backgroundImageCardView
                
                bottomButtonsView
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .foregroundColor(Color(UIColor.systemBlue))
            },
            trailing: Button(action: {
                // 保存所有修改
                saveGoal()
            }) {
                Text("保存")
                    .foregroundColor(Color(UIColor.systemBlue))
            }
        )
        .onAppear { NavigationManager.shared.goalDetailActive = true }
        .onDisappear { NavigationManager.shared.goalDetailActive = false }
        .sheet(isPresented: $showEditSheet) {
            EditFormView(
                editingField: $editingField,
                editingValue: $editingValue,
                editingProgress: $editingProgress,
                onSave: handleSaveGoalEdit
            )
            .presentationDetents(editingField == .progress ? [.medium] : [.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskView(goalId: goal.id.uuidString)
        }
        .sheet(isPresented: $showUpperGoalSelector) {
            GoalSelectorView(availableGoals: availableUpperGoals, selectedGoals: $goal.upperProject, isPresented: $showUpperGoalSelector, selectorType: "upperProject", goal: goal)
        }
        .sheet(isPresented: $showSubGoalSelector) {
            GoalSelectorView(availableGoals: availableSubGoals, selectedGoals: $goal.subProject, isPresented: $showSubGoalSelector, selectorType: "subProject", goal: goal)
        }
        .sheet(isPresented: $showContactSelector) {
            ContactSelectorView(allContacts: allContacts, selectedIds: goal.relatedContactIds, onSelect: { selectedIds in
                // 获取之前的关联联系人列表，用于后续比较
                let previousContactIds = goal.relatedContactIds
                
                // 更新目标的关联联系人列表
                goal.relatedContactIds = selectedIds
                goal.modifyTime = Date()
                
                // 找出被移除的联系人
                let removedContactIds = previousContactIds.filter { !selectedIds.contains($0) }
                
                // 找出新增的联系人
                let addedContactIds = selectedIds.filter { !previousContactIds.contains($0) }
                
                // 处理被移除的联系人：从它们的关联目标列表中移除当前目标
                for contactId in removedContactIds {
                    if let contact = allContacts.first(where: { $0.id == contactId }) {
                        var contactGoalIds = contact.relatedGoalIds
                        if let idx = contactGoalIds.firstIndex(of: goal.id) {
                            contactGoalIds.remove(at: idx)
                            contact.relatedGoalIds = contactGoalIds
                            
                            // 记录关联联系人删除
                            GoalActivityManager.shared.logContactRemove(goal: goal, contactId: contactId, contactName: contact.name)
                        }
                    }
                }
                
                // 处理新增的联系人：向它们的关联目标列表中添加当前目标
                for contactId in addedContactIds {
                    if let contact = allContacts.first(where: { $0.id == contactId }) {
                        var contactGoalIds = contact.relatedGoalIds
                        if !contactGoalIds.contains(goal.id) {
                            contactGoalIds.append(goal.id)
                            contact.relatedGoalIds = contactGoalIds
                            
                            // 记录关联联系人添加
                            GoalActivityManager.shared.logContactAdd(goal: goal, contactId: contactId, contactName: contact.name)
                        }
                    }
                }
                
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save contact relation: \(error)")
                }
            })
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedBackgroundImage, onSelect: { imageName in
                goal.backgroundImage = imageName
                goal.modifyTime = Date()
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save background image: \(error)")
                }
            })
        }
        .sheet(isPresented: $showActivityLog) {
            GoalActivityLogView(goal: goal)
        }
        // 统一在顶层挂载添加标签弹窗，确保任意“添加标签”按钮都能生效
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet(existingEntityTags: goal.tags) { names in
                let existing = Set(goal.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                let toAdd = names.filter { !existing.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
                guard !toAdd.isEmpty else { return }
                for name in toAdd {
                    goal.tags.append(name)
                    GoalActivityManager.shared.logTagAdd(goal: goal, tag: name)
                }
                goal.modifyTime = Date()
                do { try modelContext.save() } catch { print("Failed to save tag additions: \(error)") }
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("移到回收站"),
                message: Text("确定要将目标 \"\(goal.name)\" 移到回收站吗？目标将在回收站保留\(getTrashExpirationDays())天，期间可以恢复。"),
                primaryButton: .destructive(Text("移到回收站")) {
                    deleteGoal()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert("无法删除目标", isPresented: $showDependencyWarning) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(dependencyWarningMessage)
        }
        .overlay(
            Group {
                if goal.goalType == .habit {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                        // 打卡按钮点击操作
                        handleCheckIn()
                    }) {
                        VStack(spacing: 0) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14.4, weight: .black))
                                .foregroundColor(.white)
                                .scaleEffect(isCheckInAnimating ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCheckInAnimating)
                        }
                        .frame(width: 39.6, height: 39.6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.9),
                                    Color.green
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.green.opacity(0.3), radius: 12, x: 0, y: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        isPressed = pressing
                    }, perform: {})
                    .onChange(of: isCheckInAnimating) { _, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isCheckInAnimating = false
                            }
                        }
                    }
                            .padding(.trailing, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
        )
    }
}

// 编辑表单视图
struct EditFormView: View {
    @Binding var editingField: GoalDetailView.EditableField?
    @Binding var editingValue: String
    @Binding var editingProgress: Double
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    // 添加回调函数
    var onSave: ((GoalDetailView.EditableField?, String, Double) -> Void)? = nil
    
    // 提醒事项相关状态
    @State private var eventStore = EKEventStore()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 内容区域
                ScrollView {
                    VStack(spacing: 16) {
                        switch editingField {
                        case .name:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目标名称")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                
                                TextField("请输入目标名称", text: $editingValue)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                    .padding(.horizontal, 16)
                            }
                        
                        case .goalDescription:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目标描述")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 12)
                                        .padding(.leading, 12)
                                    
                                    TextEditor(text: $editingValue)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(UIColor.label))
                                        .padding(.vertical, 8)
                                        .padding(.trailing, 12)
                                        .frame(minHeight: 150)
                                        .background(Color.clear)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(UIColor.systemBlue).opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 16)
                            }
                        
                        case .progress:
                            VStack(spacing: 16) {
                                Text("\(Int(editingProgress * 100))%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Slider(value: $editingProgress, in: 0...1, step: 0.01)
                                    .padding(.horizontal, 16)
                                    .accentColor(Color.blue)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                            .padding(.horizontal, 16)
                        
                        case .tag:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("标签")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.secondary)
                                    TextField("请输入标签", text: $editingValue)
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                .padding(.horizontal, 16)
                            }
                        
                        case .upperProject:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("上级目标")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                
                                HStack {
                                    Image(systemName: "arrow.up.circle")
                                        .foregroundColor(.secondary)
                                    TextField("请输入上级目标", text: $editingValue)
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                .padding(.horizontal, 16)
                            }
                        
                        case .subProject:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("子目标")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                
                                HStack {
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.secondary)
                                    TextField("请输入子目标", text: $editingValue)
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                .padding(.horizontal, 16)
                            }
                        
                        case .task:
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("任务")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.secondary)
                                        TextField("请输入任务", text: $editingValue)
                                            .font(.system(size: 16))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                    .padding(.horizontal, 16)
                                }
                                
                                // 导入到提醒事项按钮
                                Button(action: {
                                    importToReminders()
                                }) {
                                    HStack {
                                        Image(systemName: "bell.fill")
                                        Text("导入到提醒事项")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(.white)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 16)
                            }
                        
                        case .dueDate:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("截止日期")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                    Text("请使用日期选择器设置截止日期")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                .padding(.horizontal, 16)
                            }
                        
                        case .none:
                            Text("请选择要编辑的内容")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .padding()
                            
                        @unknown default:
                            Text("未知编辑类型")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(.vertical, 20)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationBarTitle(getNavigationTitle(), displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    // 直接调用回调函数而不是发送通知
                    if let onSave = onSave {
                        onSave(editingField, editingValue, editingProgress)
                    }
                    dismiss()
                }
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("提醒事项"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func getNavigationTitle() -> String {
        switch editingField {
        case .name:
            return "编辑目标名称"
        case .goalDescription:
            return "编辑目标描述"
        case .progress:
            return "调整进度"
        case .tag:
            return editingValue.isEmpty ? "添加标签" : "编辑标签"
        case .upperProject:
            return editingValue.isEmpty ? "添加上级目标" : "编辑上级目标"
        case .subProject:
            return editingValue.isEmpty ? "添加子目标" : "编辑子目标"
        case .task:
            return editingValue.isEmpty ? "添加任务" : "编辑任务"
        case .dueDate:
            return "设置截止日期"
        case .none:
            return "编辑"
        @unknown default:
            return "编辑"
        }
    }
    
    // 导入到提醒事项的方法
    private func importToReminders() {
        // 请求访问提醒事项权限
        eventStore.requestAccess(to: .reminder) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.createReminder()
                } else {
                    self.alertMessage = "需要访问提醒事项权限才能导入任务"
                    self.showingAlert = true
                }
            }
        }
    }
    
    // 创建提醒事项
    private func createReminder() {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = editingValue.isEmpty ? "新任务" : editingValue
        reminder.notes = "从目标管理应用导入"
        
        // 获取默认的提醒事项日历
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        do {
            try eventStore.save(reminder, commit: true)
            alertMessage = "任务已成功导入到提醒事项"
            showingAlert = true
        } catch {
            alertMessage = "导入失败：\(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// 添加任务视图
struct AddTaskView: View {
    let goalId: String
    @State private var taskTitle = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]
    
    private var currentGoal: Goal? {
        allGoals.first { $0.id.uuidString == goalId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 任务标题输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text("任务标题")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.gray)
                        
                        TextField("请输入任务标题", text: $taskTitle)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .background(Color(.systemBackground))
            .navigationBarTitle("添加任务", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button(action: {
                    addTask()
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("添加")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                }
                .disabled(taskTitle.isEmpty)
                .opacity(taskTitle.isEmpty ? 0.6 : 1.0)
            )
        }
    }
    
    private func addTask() {
        guard let goal = currentGoal else { return }
        
        let newTask = GoalTask(title: taskTitle, isCompleted: false)
        newTask.goal = goal
        goal.tasks.append(newTask)
        goal.modifyTime = Date()
        
        // 记录任务添加
        GoalActivityManager.shared.logTaskAdd(goal: goal, task: newTask, modelContext: modelContext)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to add task: \(error)")
        }
    }
}

// 目标选择器视图
struct GoalSelectorView: View {
    var availableGoals: [String] // 目标ID列表
    @Binding var selectedGoals: [String] // 选中的目标ID列表
    @Binding var isPresented: Bool
    @State private var searchText = ""
    var selectorType: String // 用于区分上级目标和子目标
    let goal: Goal
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Goal> { $0.isDeleted == false }) private var allGoals: [Goal] // 添加查询未删除的目标
    
    // 根据ID获取目标名称的方法
    private func getGoalName(id: String) -> String {
        if let uuid = UUID(uuidString: id),
           let foundGoal = allGoals.first(where: { $0.id == uuid }) {
            return foundGoal.name
        }
        return "未知目标"
    }
    
    var filteredGoals: [String] {
        if searchText.isEmpty {
            return availableGoals
        } else {
            return availableGoals.filter { goalId in
                let name = getGoalName(id: goalId)
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索目标", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // 已选目标
                if !selectedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已选目标")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedGoals, id: \.self) { goalId in
                                    HStack {
                                        Text(getGoalName(id: goalId))
                                            .font(.system(size: 14))
                                        
                                        Button(action: {
                                            toggleGoalSelection(goalId)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                }
                
                // 目标列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredGoals, id: \.self) { goalId in
                            Button(action: {
                                toggleGoalSelection(goalId)
                            }) {
                                HStack {
                                    Text(getGoalName(id: goalId))
                                        .foregroundColor(.primary)
                                        .font(.system(size: 16))
                                    Spacer()
                                    if selectedGoals.contains(goalId) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitle(selectorType == "upperProject" ? "选择上级目标" : "选择子目标", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button(action: {
                    saveGoalRelation()
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("添加")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                }
            )
        }
    }
    
    private func toggleGoalSelection(_ goalId: String) {
        if let index = selectedGoals.firstIndex(of: goalId) {
            selectedGoals.remove(at: index)
        } else {
            selectedGoals.append(goalId)
        }
    }
    

    
    private func saveGoalRelation() {
        // 获取当前目标的ID字符串
        let currentGoalId = goal.id.uuidString
        
        // 处理上级目标关系
        if selectorType == "upperProject" {
            // 获取之前的上级目标列表，用于后续比较
            let previousUpperProjects = goal.upperProject
            
            // 更新当前目标的上级目标列表
            goal.upperProject = selectedGoals
            
            // 找出被移除的上级目标
            let removedUpperProjects = previousUpperProjects.filter { !selectedGoals.contains($0) }
            
            // 找出新增的上级目标
            let addedUpperProjects = selectedGoals.filter { !previousUpperProjects.contains($0) }
            
            // 将UUID字符串转换为UUID
            let removedUpperUUIDs = removedUpperProjects.compactMap { UUID(uuidString: $0) }
            let addedUpperUUIDs = addedUpperProjects.compactMap { UUID(uuidString: $0) }
            
            // 处理被移除的上级目标：从它们的子目标列表中移除当前目标
            if !removedUpperUUIDs.isEmpty {
                let removedUpperGoals = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { upperGoal in
                    removedUpperUUIDs.contains(upperGoal.id)
                }))
                
                for upperGoal in removedUpperGoals ?? [] {
                    // 记录上级目标删除
                    GoalActivityManager.shared.logUpperProjectRemove(goal: goal, upperProject: upperGoal.name, modelContext: modelContext)
                    upperGoal.subProject.removeAll(where: { $0 == currentGoalId })
                    upperGoal.modifyTime = Date()
                }
            }
            
            // 处理新增的上级目标：将当前目标添加到它们的子目标列表中
            if !addedUpperUUIDs.isEmpty {
                let addedUpperGoals = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { upperGoal in
                    addedUpperUUIDs.contains(upperGoal.id)
                }))
                
                for upperGoal in addedUpperGoals ?? [] {
                    // 记录上级目标添加
                    GoalActivityManager.shared.logUpperProjectAdd(goal: goal, upperProject: upperGoal.name, modelContext: modelContext)
                    if !upperGoal.subProject.contains(currentGoalId) {
                        upperGoal.subProject.append(currentGoalId)
                        upperGoal.modifyTime = Date()
                    }
                }
            }
        } 
        // 处理子目标关系
        else if selectorType == "subProject" {
            // 获取之前的子目标列表，用于后续比较
            let previousSubProjects = goal.subProject
            
            // 更新当前目标的子目标列表
            goal.subProject = selectedGoals
            
            // 找出被移除的子目标
            let removedSubProjects = previousSubProjects.filter { !selectedGoals.contains($0) }
            
            // 找出新增的子目标
            let addedSubProjects = selectedGoals.filter { !previousSubProjects.contains($0) }
            
            // 将UUID字符串转换为UUID
            let removedSubUUIDs = removedSubProjects.compactMap { UUID(uuidString: $0) }
            let addedSubUUIDs = addedSubProjects.compactMap { UUID(uuidString: $0) }
            
            // 处理被移除的子目标：从它们的上级目标列表中移除当前目标
            if !removedSubUUIDs.isEmpty {
                let removedSubGoals = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { subGoal in
                    removedSubUUIDs.contains(subGoal.id)
                }))
                
                for subGoal in removedSubGoals ?? [] {
                    // 记录子目标删除
                    GoalActivityManager.shared.logSubProjectRemove(goal: goal, subProject: subGoal.name, modelContext: modelContext)
                    subGoal.upperProject.removeAll(where: { $0 == currentGoalId })
                    subGoal.modifyTime = Date()
                }
            }
            
            // 处理新增的子目标：将当前目标添加到它们的上级目标列表中
            if !addedSubUUIDs.isEmpty {
                let addedSubGoals = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { subGoal in
                    addedSubUUIDs.contains(subGoal.id)
                }))
                
                for subGoal in addedSubGoals ?? [] {
                    // 记录子目标添加
                    GoalActivityManager.shared.logSubProjectAdd(goal: goal, subProject: subGoal.name, modelContext: modelContext)
                    if !subGoal.upperProject.contains(currentGoalId) {
                        subGoal.upperProject.append(currentGoalId)
                        subGoal.modifyTime = Date()
                    }
                }
            }
        }
        
        goal.modifyTime = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save goal relation: \(error)")
        }
    }
}

#Preview {
    // 创建预览数据的函数
    func createPreviewGoal() -> Goal {
        let previewGoal = Goal(
            name: "目标名称",
            description: "描述一下这个目标的具体内容",
            progress: 0.7,
            backgroundImage: nil,
            tags: ["tag1", "tag2", "tag3"],
            upperProject: ["上级目标1", "上级目标2"],
            subProject: ["子目标1", "子目标2"],
            recordNum: 5,
            category: "技能提升",
            dueDate: Date()
        )
        
        let task1 = GoalTask(title: "子任务1", isCompleted: true)
        let task2 = GoalTask(title: "子任务2", isCompleted: false)
        task1.goal = previewGoal
        task2.goal = previewGoal
        previewGoal.tasks.append(task1)
        previewGoal.tasks.append(task2)
        
        return previewGoal
    }
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, GoalTask.self, configurations: config)
    
    return NavigationView {
        GoalDetailView(goal: createPreviewGoal())
    }
    .modelContainer(container)
}
