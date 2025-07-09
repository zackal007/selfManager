//
//  GoalDetailView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import UIKit

struct GoalDetailView: View {
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
        case description
        case progress
        case tag
        case upperProject
        case subProject
        case task
        case dueDate
    }
    
    // 计算属性
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
    
    // 日期选择状态
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    
    // 目标类型选择状态
    @State private var selectedGoalType = 0
    @State private var showGoalTypeMenu = false
    private let goalTypes = ["人生", "年度", "短期"]
    
    // 可选目标列表
    @State private var availableUpperGoals: [String] = ["人生目标1", "年度目标1", "短期目标1", "其他目标1", "其他目标2"]
    @State private var availableSubGoals: [String] = ["子目标1", "子目标2", "子目标3", "子目标4", "子目标5"]
    @State private var showUpperGoalSelector = false
    @State private var showSubGoalSelector = false
    
    // 初始化方法，设置通知监听
    init(goal: Goal) {
        _goal = State(initialValue: goal)
        
        // 添加通知监听器
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SaveGoalEdit"), object: nil, queue: .main) { [self] notification in
            handleSaveGoalEdit(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SaveGoalDueDate"), object: nil, queue: .main) { [self] notification in
            handleSaveGoalDueDate(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AddGoalTask"), object: nil, queue: .main) { [self] notification in
            handleAddGoalTask(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SaveGoalRelation"), object: nil, queue: .main) { [self] notification in
            handleSaveGoalRelation(notification: notification)
        }
    }
    
    // 处理保存目标编辑的通知
    private func handleSaveGoalEdit(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let field = userInfo["field"] as? EditableField else { return }
        
        switch field {
        case .name:
            if let value = userInfo["value"] as? String {
                goal.name = value
            }
        case .description:
            if let value = userInfo["value"] as? String {
                goal.description = value
            }
        case .progress:
            if let progress = userInfo["progress"] as? Double {
                goal.progress = progress
            }
        case .tag:
            if let value = userInfo["value"] as? String, !value.isEmpty {
                // 添加新标签
                if !goal.tags.contains(value) {
                    goal.tags.append(value)
                }
            }
        case .upperProject, .subProject, .task, .dueDate, .none:
            // 这些字段在其他地方处理
            break
        }
        
        // 更新修改时间
        goal.modifyTime = Date()
    }
    
    // 处理保存截止日期的通知
    private func handleSaveGoalDueDate(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let selectedDate = userInfo["selectedDate"] as? Date else { return }
        
        goal.dueDate = selectedDate
        goal.modifyTime = Date()
    }
    
    // 处理添加任务的通知
    private func handleAddGoalTask(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let taskTitle = userInfo["taskTitle"] as? String else { return }
        
        let newTask = Task(id: UUID().uuidString, title: taskTitle, completed: false)
        goal.tasks.append(newTask)
        goal.modifyTime = Date()
    }
    
    // 处理保存目标关系的通知
    private func handleSaveGoalRelation(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let relationType = userInfo["relationType"] as? String,
              let selectedGoals = userInfo["selectedGoals"] as? [String] else { return }
        
        switch relationType {
        case "upperProject":
            goal.upperProject = selectedGoals
        case "subProject":
            goal.subProject = selectedGoals
        default:
            break
        }
        
        goal.modifyTime = Date()
    }
    
    // 保存目标的所有修改
    private func saveGoal() {
        // 更新修改时间
        goal.modifyTime = Date()
        
        // 发送通知，通知其他视图目标已更新
        NotificationCenter.default.post(
            name: NSNotification.Name("GoalUpdated"),
            object: nil,
            userInfo: ["goal": goal]
        )
        
        // 显示保存成功提示
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 返回上一个视图
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 滚动内容
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 顶部留白（为固定头部预留空间）
                    Color.clear.frame(height: 220) // 根据固定头部的高度调整
                    
                    // 截止日期（移到tag下方）
                    HStack(spacing: 4) {
                        Text("截止日期: ")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Button(action: {
                            // 打开日期选择器
                            editingField = .dueDate
                            selectedDate = goal.dueDate ?? Date()
                            showDatePicker = true
                        }) {
                            Text(formattedDueDate)
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.systemBlue))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 上级目标和子目标
                HStack(spacing: 12) {
                    // 上级目标
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("上级目标:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            Spacer()
                            
                            // 添加上级目标按钮
                            Button(action: {
                                showUpperGoalSelector = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(goal.upperProject, id: \.self) { project in
                                    HStack {
                                        // 目标名称
                                        Text(project)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(UIColor.systemBlue))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // 删除按钮
                                        Button(action: {
                                            // 删除上级目标
                                            if let index = goal.upperProject.firstIndex(of: project) {
                                                goal.upperProject.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(UIColor.systemGray3))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(12)
                    .frame(width: (UIScreen.main.bounds.width - 16*2 - 12) / 2)
                    .frame(height: 150)
                    // 子目标
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("子目标:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            Spacer()
                            
                            // 添加子目标按钮
                            Button(action: {
                                showSubGoalSelector = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(goal.subProject, id: \.self) { project in
                                    HStack {
                                        // 目标名称
                                        Text(project)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(UIColor.systemBlue))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // 删除按钮
                                        Button(action: {
                                            // 删除子目标
                                            if let index = goal.subProject.firstIndex(of: project) {
                                                goal.subProject.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(UIColor.systemGray3))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(12)
                    .frame(width: (UIScreen.main.bounds.width - 16*2 - 12) / 2)
                    .frame(height: 150)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // 子任务
                VStack(alignment: .leading, spacing: 12) {
                    Text("子任务:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    ForEach(goal.tasks) { task in
                        HStack(spacing: 12) {
                            // 复选框（参考备忘录样式）
                            Button(action: {
                                // 切换任务完成状态
                                // 在实际应用中，需要通过ViewModel或状态管理来更新
                                if let index = goal.tasks.firstIndex(where: { $0.id == task.id }) {
                                    goal.tasks[index].isCompleted.toggle()
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
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 任务标题
                            Button(action: {
                                editingField = .task
                                editingValue = task.title
                                showEditSheet = true
                            }) {
                                Text(task.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(UIColor.label))
                                    .strikethrough(task.isCompleted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 删除按钮
                            Button(action: {
                                // 删除任务
                                // 在实际应用中，需要通过ViewModel或状态管理来更新
                                if let index = goal.tasks.firstIndex(where: { $0.id == task.id }) {
                                    goal.tasks.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.systemRed))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                    }
                    
                    // 添加任务按钮
                    Button(action: {
                        // 打开添加任务表单
                        showAddTaskSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(UIColor.systemBlue))
                            
                            Text("添加任务")
                                .font(.system(size: 16))
                                .foregroundColor(Color(UIColor.systemBlue))
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                    }
                }
                .padding(.bottom, 16)
                
                // 目标类型内容（替代原来的分段控制器）
                VStack(alignment: .leading, spacing: 8) {
                    Text("目标类型")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    // 这里显示选中的目标类型内容
                    Text("短期目标内容")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.label))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // 添加一个实际的View组件替代注释
                VStack {
                    Text("目标进度详情")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("返回")
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
        
        // 固定在顶部的内容
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                // 目标名称和进度
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
                    // 进度环形指示器（放大1.5倍）
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // 下拉菜单（替代分段控制器）
                Menu {
                    ForEach(0..<goalTypes.count, id: \.self) { index in
                        Button(action: {
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
                
                // 目标描述
                Button(action: {
                    editingField = .description
                    editingValue = goal.description
                    showEditSheet = true
                }) {
                    Text(goal.description)
                        .font(.system(size: 16))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 标签
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(goal.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#")
                                    .foregroundColor(Color(UIColor.systemBlue))
                                Text(tag)
                                    .foregroundColor(Color(UIColor.systemBlue))
                                
                                // 删除标签按钮
                                Button(action: {
                                    // 删除标签
                                    if let index = goal.tags.firstIndex(of: tag) {
                                        goal.tags.remove(at: index)
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
            .padding(.bottom, 16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .top)
            , alignment: .top
        )
        .sheet(isPresented: $showEditSheet) {
            // 编辑目标的表单视图
            EditFormView(editingField: $editingField, editingValue: $editingValue, editingProgress: $editingProgress)
        }
        .sheet(isPresented: $showDatePicker) {
            // 日期选择器视图
            DatePickerView(selectedDate: $selectedDate, isPresented: $showDatePicker)
        }
        .sheet(isPresented: $showAddTaskSheet) {
            // 添加任务的表单视图
            AddTaskView(goalId: goal.id)
        }
        .sheet(isPresented: $showUpperGoalSelector) {
            // 上级目标选择器视图
            GoalSelectorView(availableGoals: availableUpperGoals, selectedGoals: $goal.upperProject, isPresented: $showUpperGoalSelector, selectorType: "upperProject")
        }
        .sheet(isPresented: $showSubGoalSelector) {
            // 子目标选择器视图
            GoalSelectorView(availableGoals: availableSubGoals, selectedGoals: $goal.subProject, isPresented: $showSubGoalSelector, selectorType: "subProject")
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48) // 原来60*0.8=48
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
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
    
    var body: some View {
        NavigationView {
            Form {
                switch editingField {
                case .name:
                    TextField("目标名称", text: $editingValue)
                        .font(.system(size: 18))
                
                case .description:
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
                }
            }
            .navigationBarTitle(getNavigationTitle(), displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    // 保存修改的内容到数据模型
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SaveGoalEdit"),
                        object: nil,
                        userInfo: [
                            "field": editingField as Any,
                            "value": editingValue,
                            "progress": editingProgress
                        ]
                    )
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func getNavigationTitle() -> String {
        switch editingField {
        case .name:
            return "编辑目标名称"
        case .description:
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
        }
    }
}

// 添加任务视图
struct AddTaskView: View {
    let goalId: String
    @State private var taskTitle = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $taskTitle)
                }
            }
            .navigationBarTitle("添加任务", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("添加") {
                    // 添加新任务到数据模型
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AddGoalTask"),
                        object: nil,
                        userInfo: [
                            "goalId": goalId,
                            "taskTitle": taskTitle
                        ]
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(taskTitle.isEmpty)
            )
        }
    }
}

// 日期选择器视图
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
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
                    // 保存选择的日期到数据模型
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SaveGoalDueDate"),
                        object: nil,
                        userInfo: ["selectedDate": selectedDate]
                    )
                    isPresented = false
                }
            )
        }
    }
}

struct GoalSelectorView: View {
    var availableGoals: [String]
    @Binding var selectedGoals: [String]
    @Binding var isPresented: Bool
    @State private var searchText = ""
    var selectorType: String // 用于区分上级目标和子目标
    
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
                    // 保存选择的目标
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SaveGoalRelation"),
                        object: nil,
                        userInfo: [
                            "relationType": selectorType,
                            "selectedGoals": selectedGoals
                        ]
                    )
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
}

#Preview {
    NavigationView {
        GoalDetailView(goal: Goal(
            id: UUID(),
            name: "目标名称",
            description: "描述一下这个目标的具体内容",
            progress: 0.7,
            tasks: [
                Task(id: 1, title: "子任务1", isCompleted: true),
                Task(id: 2, title: "子任务2", isCompleted: false)
            ],
            backgroundImage: nil,
            tags: ["tag1", "tag2", "tag3"],
            upperProject: ["上级目标1", "上级目标2"],
            subProject: ["子目标1", "子目标2"],
            recordNum: 5,
            category: "技能提升",
            createTime: Date(),
            modifyTime: Date(),
            visitTime: Date(),
            dueDate: nil
        ))
    }
}