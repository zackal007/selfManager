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

struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]
    
    // 状态变量
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showUpperGoalSelector = false
    @State private var showSubGoalSelector = false
    @State private var showDeleteAlert = false
    @State private var selectedGoalType = 0
    
    // 常量
    private let goalTypes = ["人生目标", "年度目标", "短期目标"]
    private var availableUpperGoals: [String] {
        allGoals.map { $0.name }.filter { $0 != goal.name }
    }
    private var availableSubGoals: [String] { 
        allGoals.map { $0.name }.filter { $0 != goal.name }
    }
    
    // 目标对象
    @State var goal: Goal
    
    // 状态变量
    @State private var showEditSheet = false
    @State private var showAddTaskSheet = false
    @State private var editingField: EditableField? = nil
    @State private var editingValue: String = ""
    @State private var editingProgress: Double = 0
    @Environment(\.presentationMode) var presentationMode
    
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
        case none
    }
    
    // 计算属性
    
    // 截止日期视图
    private var dueDateView: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(Color(UIColor.systemBlue))
                .frame(width: 24, height: 24)
            
            Text("截止日期")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            Button(action: {
                // 打开日期选择器
                editingField = .dueDate
                selectedDate = goal.dueDate ?? Date()
                showingDatePicker = true
            }) {
                Text(formattedDueDate)
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
                VStack(spacing: 10) {
                    ForEach(goal.tasks.indices, id: \.self) { index in
                        let task = goal.tasks[index]
                        HStack(spacing: 12) {
                            // 复选框（参考备忘录样式）
                            Button(action: {
                                // 切换任务完成状态
                                goal.tasks[index].isCompleted.toggle()
                                goal.modifyTime = Date()
                                
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to save task update: \(error)")
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(task.isCompleted ? Color.clear : Color(UIColor.systemGray3), lineWidth: 1.5)
                                        .frame(width: 22, height: 22)
                                    
                                    if task.isCompleted {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 22, height: 22)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 任务名称
                            Text(task.title)
                                .font(.system(size: 15))
                                .foregroundColor(task.isCompleted ? Color(UIColor.systemGray) : Color(UIColor.label))
                                .strikethrough(task.isCompleted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 删除按钮
                            Button(action: {
                                // 删除任务
                                let taskToDelete = goal.tasks[index]
                                goal.tasks.remove(at: index)
                                modelContext.delete(taskToDelete)
                                goal.modifyTime = Date()
                                
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to delete task: \(error)")
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.systemRed))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
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
                                
                                // 目标名称
                                Text(project)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(UIColor.label))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 删除按钮
                                Button(action: {
                                    // 删除上级目标
                                    if let index = goal.upperProject.firstIndex(of: project) {
                                        goal.upperProject.remove(at: index)
                                        // 更新修改时间
                                        goal.modifyTime = Date()
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
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
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
                                
                                // 目标名称
                                Text(project)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(UIColor.label))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 删除按钮
                                Button(action: {
                                    // 删除子目标
                                    if let index = goal.subProject.firstIndex(of: project) {
                                        goal.subProject.remove(at: index)
                                        // 更新修改时间
                                        goal.modifyTime = Date()
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
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
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
    }
    
    // 处理保存目标编辑
    private func handleSaveGoalEdit(field: EditableField?, value: String, progress: Double) {
        guard let field = field else { return }
        
        switch field {
        case .name:
            goal.name = value
        case .goalDescription:
            goal.goalDescription = value
        case .progress:
            goal.progress = progress
        case .tag:
            if !value.isEmpty {
                // 添加新标签
                if !goal.tags.contains(value) {
                    goal.tags.append(value)
                }
            }
        case .upperProject, .subProject, .task, .dueDate, .none:
            // 这些字段在其他地方处理
            break
        @unknown default:
            // 处理未来可能添加的枚举值
            print("未知的编辑字段类型")
            break
        }
        
        // 更新修改时间
        goal.modifyTime = Date()
    }
    
    // 此方法已被移除，因为 DatePickerView 直接使用 modelContext 保存数据
    
    // 此方法已被移除，因为 AddTaskView 直接使用 modelContext 保存数据
    
    // 此方法已被移除，因为 GoalSelectorView 直接使用 modelContext 保存数据
    
    // 保存目标的所有修改
    private func saveGoal() -> Void {
        // 根据selectedGoalType更新goal.goalType
        switch selectedGoalType {
        case 0:
            goal.goalType = .life
        case 1:
            goal.goalType = .yearly
        case 2:
            goal.goalType = .shortTerm
        case 3:
            goal.goalType = .habit
        default:
            break
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
    
    // 删除目标
    private func deleteGoal() {
        // 删除关联的任务
        for task in goal.tasks {
            modelContext.delete(task)
        }
        
        // 处理上级目标关联
        let goalId = goal.id
        let upperGoalIds = goal.upperProject
        let subGoalIds = goal.subProject
        
        // 将ID字符串数组转换为UUID数组
        let upperGoalUUIDs = upperGoalIds.compactMap { UUID(uuidString: $0) }
        let subGoalUUIDs = subGoalIds.compactMap { UUID(uuidString: $0) }

        // 查询并更新上级目标
        if !upperGoalUUIDs.isEmpty {
            let upperGoals = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { upperGoal in
                upperGoalUUIDs.contains(upperGoal.id)
            }))
            
            for upperGoal in upperGoals ?? [] {
                upperGoal.subProject.removeAll(where: { $0 == goalId.uuidString })
                upperGoal.modifyTime = Date()
            }
        }
        
        // 查询并更新子目标
        if !subGoalUUIDs.isEmpty {
            let subGoals = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { subGoal in
                subGoalUUIDs.contains(subGoal.id)
            }))
            
            for subGoal in subGoals ?? [] {
                subGoal.upperProject.removeAll(where: { $0 == goalId.uuidString })
                subGoal.modifyTime = Date()
            }
        }
        
        // 删除目标本身
        modelContext.delete(goal)
        
        // 保存更改
        try? modelContext.save()
        
        // 返回上一个视图
        presentationMode.wrappedValue.dismiss()
    }
    
    // 固定头部视图
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 目标名称和进度
            goalNameProgressView
            
            // 下拉菜单
            goalTypeMenuView
            
            // 目标描述
            goalDescriptionView
            
            // 标签
            goalTagsView
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
                            .foregroundColor(Color(UIColor.systemBlue))
                        
                        // 删除标签按钮
                        Button(action: {
                            // 删除标签
                            if let index = goal.tags.firstIndex(of: tag) {
                                goal.tags.remove(at: index)
                                // 更新修改时间
                                goal.modifyTime = Date()
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
                
                // 添加标签按钮
                Button(action: {
                    editingField = .tag
                    editingValue = ""
                    showEditSheet = true
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
            Button(action: {
                editingField = .name
                editingValue = goal.name
                showEditSheet = true
            }) {
                Text(goal.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
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
        Button(action: {
            editingField = .goalDescription
            editingValue = goal.goalDescription
            showEditSheet = true
        }) {
            HStack {
                Text(goal.goalDescription)
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 目标信息卡片
                VStack(alignment: .leading, spacing: 16) {
                    // 目标名称和进度
                    goalNameProgressView
                    
                    // 目标类型
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
                    
                    // 目标描述
                    VStack(alignment: .leading, spacing: 8) {
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
                        
                        Button(action: {
                            editingField = .goalDescription
                            editingValue = goal.goalDescription
                            showEditSheet = true
                        }) {
                            HStack {
                                Text(goal.goalDescription)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(UIColor.label))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 16)
                    
                    // 标签
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
                            
                            // 添加标签按钮
                            Button(action: {
                                editingField = .tag
                                editingValue = ""
                                showEditSheet = true
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
                        .padding(.horizontal, 16)
                        
                        if goal.tags.isEmpty {
                            Text("暂无标签")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(goal.tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .foregroundColor(Color(UIColor.systemBlue))
                                            
                                            // 删除标签按钮
                                            Button(action: {
                                                // 删除标签
                                                if let index = goal.tags.firstIndex(of: tag) {
                                                    goal.tags.remove(at: index)
                                                    // 更新修改时间
                                                    goal.modifyTime = Date()
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
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                            }
                            .frame(height: 40)
                        }
                    }
                    
                    // 截止日期
                    dueDateView
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // 上级目标和子目标卡片
                VStack(alignment: .leading, spacing: 16) {
                    Text("目标关联")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(.horizontal, 16)
                    
                    projectsView
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // 子任务卡片
                VStack(alignment: .leading, spacing: 16) {
                    Text("子任务")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(.horizontal, 16)
                    
                    // 子任务列表
                    VStack(alignment: .leading, spacing: 12) {
                        if goal.tasks.isEmpty {
                            Text("暂无子任务")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(goal.tasks.indices, id: \.self) { index in
                                let task = goal.tasks[index]
                                HStack(spacing: 12) {
                                    // 复选框
                                    Button(action: {
                                        goal.tasks[index].isCompleted.toggle()
                                        goal.modifyTime = Date()
                                        
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to save task update: \(error)")
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .stroke(task.isCompleted ? Color.clear : Color(UIColor.systemGray3), lineWidth: 1.5)
                                                .frame(width: 22, height: 22)
                                            
                                            if task.isCompleted {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 22, height: 22)
                                                
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // 任务名称
                                    Text(task.title)
                                        .font(.system(size: 16))
                                        .foregroundColor(task.isCompleted ? Color(UIColor.systemGray) : Color(UIColor.label))
                                        .strikethrough(task.isCompleted)
                                    
                                    Spacer()
                                    
                                    // 删除按钮
                                    Button(action: {
                                        let taskToDelete = goal.tasks[index]
                                        goal.tasks.remove(at: index)
                                        modelContext.delete(taskToDelete)
                                        goal.modifyTime = Date()
                                        
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to delete task: \(error)")
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(UIColor.systemRed))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                
                                if index < goal.tasks.count - 1 {
                                    Divider()
                                        .padding(.leading, 50)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        
                        // 添加任务按钮
                        Button(action: {
                            showAddTaskSheet = true
                        }) {
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
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // 底部删除按钮
                Button(action: {
                    showDeleteAlert = true
                }) {
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
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
        .sheet(isPresented: $showEditSheet) {
            EditFormView(editingField: $editingField, editingValue: $editingValue, editingProgress: $editingProgress, onSave: handleSaveGoalEdit)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker, goal: goal)
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
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除目标 \"\(goal.name)\" 吗？此操作将同时删除所有关联的任务，且无法恢复。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteGoal()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // 点击hit按钮的操作
                    }) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
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
    
    // 添加回调函数
    var onSave: ((GoalDetailView.EditableField?, String, Double) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                switch editingField {
                case .name:
                    TextField("目标名称", text: $editingValue)
                        .font(.system(size: 18))
                
                case .goalDescription:
                    TextEditor(text: $editingValue)
                        .frame(minHeight: 100)
                
                case .progress:
                    VStack {
                        Text("\(Int(editingProgress * 100))%")
                            .font(.title)
                            .bold()
                            .padding()
                        
                        Slider(value: $editingProgress, in: 0...1, step: 0.01)
                            .padding(.horizontal)
                    }
                
                case .tag:
                    TextField("标签", text: $editingValue)
                        .font(.system(size: 16))
                
                case .upperProject:
                    TextField("上级目标", text: $editingValue)
                        .font(.system(size: 16))
                
                case .subProject:
                    TextField("子目标", text: $editingValue)
                        .font(.system(size: 16))
                
                case .task:
                    TextField("任务", text: $editingValue)
                        .font(.system(size: 16))
                
                case .dueDate:
                    Text("请使用日期选择器设置截止日期")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                
                case .none:
                    Text("请选择要编辑的内容")
                    
                @unknown default:
                    Text("未知编辑类型")
                }
            }
            .navigationBarTitle(getNavigationTitle(), displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    // 直接调用回调函数而不是发送通知
                    if let onSave = onSave {
                        onSave(editingField, editingValue, editingProgress)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
}

// 添加任务视图
struct AddTaskView: View {
    let goalId: String
    @State private var taskTitle = ""
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]
    
    private var currentGoal: Goal? {
        allGoals.first { $0.id.uuidString == goalId }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $taskTitle)
                }
            }
            .navigationBarTitle("添加任务", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("取消")
                },
                trailing: Button(action: {
                    addTask()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("添加")
                }
                .disabled(taskTitle.isEmpty)
            )
        }
    }
    
    private func addTask() {
        guard let goal = currentGoal else { return }
        
        let newTask = GoalTask(title: taskTitle, isCompleted: false)
        newTask.goal = goal
        goal.tasks.append(newTask)
        goal.modifyTime = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to add task: \(error)")
        }
    }
}

// 日期选择器视图
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let goal: Goal
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            }
            .navigationBarTitle("选择截止日期", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("确定") {
                    saveDueDate()
                    isPresented = false
                }
            )
        }
    }
    
    private func saveDueDate() {
        goal.dueDate = selectedDate
        goal.modifyTime = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save due date: \(error)")
        }
    }
}

struct GoalSelectorView: View {
    var availableGoals: [String]
    @Binding var selectedGoals: [String]
    @Binding var isPresented: Bool
    @State private var searchText = ""
    var selectorType: String // 用于区分上级目标和子目标
    let goal: Goal
    @Environment(\.modelContext) private var modelContext
    
    var filteredGoals: [String] {
        if searchText.isEmpty {
            return availableGoals
        } else {
            return availableGoals.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索栏
                TextField("搜索目标", text: $searchText)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 15)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 15)
                                }
                            }
                        }
                    )
                    .padding(.top, 10)
                
                List {
                    ForEach(filteredGoals, id: \.self) { goal in
                        Button(action: {
                            toggleGoalSelection(goal)
                        }) {
                            HStack {
                                Text(goal)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("选择目标", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    saveGoalRelation()
                    isPresented = false
                }
            )
        }
    }
    
    private func toggleGoalSelection(_ goal: String) {
        if let index = selectedGoals.firstIndex(of: goal) {
            selectedGoals.remove(at: index)
        } else {
            selectedGoals.append(goal)
        }
    }
    
    private func saveGoalRelation() {
        if selectorType == "upperProject" {
            goal.upperProject = selectedGoals
        } else if selectorType == "subProject" {
            goal.subProject = selectedGoals
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
