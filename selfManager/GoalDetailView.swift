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
    @Query private var allContacts: [Contact]
    
    // 状态变量
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
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
    
    // 根据目标名称获取目标对象
    private func getGoalByName(name: String) -> Goal? {
        // 首先尝试通过UUID查找（如果名称是UUID字符串）
        if let uuid = UUID(uuidString: name) {
            let descriptor = FetchDescriptor<Goal>(predicate: #Predicate<Goal> { goal in
                goal.id == uuid
            })
            return try? modelContext.fetch(descriptor).first
        }
        
        // 如果不是UUID或通过UUID未找到，则通过名称查找
        let descriptor = FetchDescriptor<Goal>(predicate: #Predicate<Goal> { goal in
            goal.name == name
        })
        return try? modelContext.fetch(descriptor).first
    }
    @State private var selectedBackgroundImage: String? = nil
    
    // 常量
    private let goalTypes = ["人生目标", "年度目标", "短期目标", "习惯"]
    private let backgroundImages = ["GoalBackground", "GoalBackground2", nil]
    private var availableUpperGoals: [String] {
        allGoals.filter { $0.id != goal.id }.map { $0.id.uuidString }
    }
    private var availableSubGoals: [String] { 
        allGoals.filter { $0.id != goal.id }.map { $0.id.uuidString }
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
        case backgroundImage
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
                List {
                    ForEach(goal.tasks) { task in
                        HStack(spacing: 12) {
                            // 复选框（参考备忘录样式）
                            Button(action: {
                                // 切换任务完成状态
                                task.isCompleted.toggle()
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
                }
                .listStyle(.plain)
                .frame(height: CGFloat(goal.tasks.count) * 60) // 动态调整高度
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
        case .task:
            if let task = editingTask {
                task.title = value
            }        case .upperProject, .subProject, .dueDate, .none:
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
    
    // 删除任务
    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let taskToDelete = goal.tasks[index]
            modelContext.delete(taskToDelete)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete task: \(error)")
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
                .onChange(of: editingImportance) { newValue in
                    goal.importance = newValue
                    goal.modifyTime = Date()
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
                    
                        // 背景图片选择部分已移至独立卡片
                    
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
                    
                    // 优先级选择器
                    VStack(alignment: .leading, spacing: 8) {
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
                            .onChange(of: editingImportance) { newValue in
                                goal.importance = newValue
                                goal.modifyTime = Date()
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to save importance: \(error)")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 16)
                    
                    // 关联人选择区已移至独立卡片
                    
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
                            List {
                                ForEach(goal.tasks) { task in
                                    HStack(spacing: 12) {
                                        // 复选框
                                        Button(action: {
                                            task.isCompleted.toggle()
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
                                .onDelete(perform: deleteTask)
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(goal.tasks.count) * 70) // 动态调整高度
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
                
                // 关联人卡片
                VStack(alignment: .leading, spacing: 16) {
                    Text("关联人")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(UIColor.systemBlue))
                                .frame(width: 24, height: 24)
                            Text("关联人")
                                .font(.system(size: 16, weight: .medium))
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
                        // 已选联系人列表
                        if goal.relatedContactIds.isEmpty {
                            Text("未关联联系人")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(goal.relatedContactIds, id: \ .self) { id in
                                        if let contact = allContacts.first(where: { $0.id == id }) {
                                            HStack(spacing: 4) {
                                                Text(contact.name)
                                                    .foregroundColor(Color(UIColor.systemBlue))
                                                Button(action: {
                                                    if let idx = goal.relatedContactIds.firstIndex(of: id) {
                                                        goal.relatedContactIds.remove(at: idx)
                                                        goal.modifyTime = Date()
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
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // 背景图片卡片
                VStack(alignment: .leading, spacing: 16) {
                    Text("背景图片")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(UIColor.systemBlue))
                                .frame(width: 24, height: 24)
                            
                            Text("背景图片")
                                .font(.system(size: 16, weight: .medium))
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
                        }
                        .padding(.horizontal, 16)
                        
                        // 显示当前背景图片预览
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(backgroundImages, id: \.self) { imageName in
                                    Button(action: {
                                        goal.backgroundImage = imageName
                                        goal.modifyTime = Date()
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to save background image: \(error)")
                                        }
                                    }) {
                                        if let imageName = imageName, let uiImage = UIImage(named: imageName) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 60)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(goal.backgroundImage == imageName ? Color.blue : Color.clear, lineWidth: 2)
                                                )
                                        } else {
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
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
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
        .sheet(isPresented: $showContactSelector) {
            ContactSelectorView(allContacts: allContacts, selectedIds: goal.relatedContactIds, onSelect: { selectedIds in
                goal.relatedContactIds = selectedIds
                goal.modifyTime = Date()
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
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("移到回收站"),
                message: Text("确定要将目标 \"\(goal.name)\" 移到回收站吗？目标将在回收站保留30天，期间可以恢复。"),
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
    var availableGoals: [String] // 目标ID列表
    @Binding var selectedGoals: [String] // 选中的目标ID列表
    @Binding var isPresented: Bool
    @State private var searchText = ""
    var selectorType: String // 用于区分上级目标和子目标
    let goal: Goal
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal] // 添加查询所有目标
    
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
                    ForEach(filteredGoals, id: \.self) { goalId in
                        Button(action: {
                            toggleGoalSelection(goalId)
                        }) {
                            HStack {
                                Text(getGoalName(id: goalId))
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedGoals.contains(goalId) {
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
