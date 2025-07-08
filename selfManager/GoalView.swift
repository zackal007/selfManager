//
//  GoalView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import UIKit

struct GoalView: View {
    // 分段控制器选择
    @State private var selectedSegment = 0
    
    // 视图模式：画廊视图或列表视图
    @State private var viewMode: ViewMode = .gallery
    
    // 分类和排序选项
    @State private var categoryOption: CategoryOption = .time
    @State private var sortOption: SortOption = .name
    
    // 显示菜单
    @State private var showMenu = false
    
    // 添加目标的状态变量
    @State private var showAddGoalSheet = false
    
    // MARK: - 菜单组件
    // 视图模式菜单内容
    private var viewModeMenuContent: some View {
        Group {
            Button(action: {
                viewMode = .gallery
            }) {
                Label("画廊视图", systemImage: "square.grid.2x2")
                if viewMode == .gallery {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                viewMode = .list
            }) {
                Label("列表视图", systemImage: "list.bullet")
                if viewMode == .list {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    // 分类菜单内容
    private var categoryMenuContent: some View {
        Menu {
            Button(action: {
                categoryOption = .time
            }) {
                Label("时间", systemImage: "")
                if categoryOption == .time {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                categoryOption = .type
            }) {
                Label("类型", systemImage: "")
                if categoryOption == .type {
                    Image(systemName: "checkmark")
                }
            }
        } label: {
            Label("分类", systemImage: "folder")
        }
    }
    
    // 排序菜单内容
    private var sortMenuContent: some View {
        Menu {
            Button(action: {
                sortOption = .name
            }) {
                Label("名称", systemImage: "")
                if sortOption == .name {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .createTime
            }) {
                Label("创建时间", systemImage: "")
                if sortOption == .createTime {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .modifyTime
            }) {
                Label("修改时间", systemImage: "")
                if sortOption == .modifyTime {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .visitTime
            }) {
                Label("访问时间", systemImage: "")
                if sortOption == .visitTime {
                    Image(systemName: "checkmark")
                }
            }
        } label: {
            Label("排序", systemImage: "arrow.up.arrow.down")
        }
    }
    
    // 目标数据
    private let yearGoals = [
        Goal(id: UUID(), name: "提高编程技能", description: "掌握Swift和SwiftUI开发，完成5个实际项目", progress: 0.65, tasks: [
            Task(id: 1, title: "完成SwiftUI基础课程", isCompleted: true),
            Task(id: 2, title: "开发一个完整的iOS应用", isCompleted: false)
        ], backgroundImage: "GoalBackground", tags: ["技能", "编程", "学习"], 
        upperProject: ["年度成长计划"], subProject: ["iOS开发", "Swift学习"], 
        recordNum: 5, category: "技能提升", 
        createTime: Date(), modifyTime: Date(), visitTime: Date()),
        
        Goal(id: UUID(), name: "健康生活", description: "保持健康的生活方式，增强体质", progress: 0.25, tasks: [
            Task(id: 3, title: "每周锻炼3次", isCompleted: true),
            Task(id: 4, title: "保持健康饮食", isCompleted: true)
        ], backgroundImage: "GoalBackground2", tags: ["健康", "运动", "饮食"], 
        upperProject: ["年度生活计划"], subProject: ["健身计划", "饮食计划"], 
        recordNum: 3, category: "健康管理", 
        createTime: Date(), modifyTime: Date(), visitTime: Date())
    ]
    
    private let periodGoals = [
        Goal(id: UUID(), name: "阅读计划", description: "拓展知识面，提高阅读量", progress: 0.45, tasks: [
            Task(id: 5, title: "阅读10本技术书籍", isCompleted: false),
            Task(id: 6, title: "每天阅读30分钟", isCompleted: false)
        ], backgroundImage: "GoalBackground", tags: ["阅读", "学习", "知识"], 
        upperProject: ["自我提升"], subProject: ["技术阅读", "每日阅读"], 
        recordNum: 2, category: "知识获取", 
        createTime: Date(), modifyTime: Date(), visitTime: Date()),
        
        Goal(id: UUID(), name: "旅行计划", description: "探索新的地方，体验不同文化", progress: 0.85, tasks: [
            Task(id: 7, title: "制定旅行路线", isCompleted: true),
            Task(id: 8, title: "预订机票和酒店", isCompleted: true)
        ], backgroundImage: nil, tags: ["旅行", "探索", "文化"], 
        upperProject: ["生活体验"], subProject: ["路线规划", "预订管理"], 
        recordNum: 4, category: "休闲娱乐", 
        createTime: Date(), modifyTime: Date(), visitTime: Date())
    ]
    
    // 新添加的目标数组
    @State private var addedGoals: [Goal] = []
    
    // 当前年份
    @State private var currentYear = 2025
    
    // 根据分类和排序选项处理后的目标数据
    private var processedYearGoals: [Goal] {
        return sortGoals(categorizeGoals(yearGoals))
    }
    
    private var processedPeriodGoals: [Goal] {
        // 合并原有的短期目标和新添加的目标
        let allPeriodGoals = periodGoals + addedGoals
        return sortGoals(categorizeGoals(allPeriodGoals))
    }
    
    // 根据分类选项对目标进行分类
    private func categorizeGoals(_ goals: [Goal]) -> [Goal] {
        switch categoryOption {
        case .time:
            // 按时间分类，这里简单返回原始数据，实际应用中可以按创建时间或修改时间分组
            return goals
        case .type:
            // 按类型分类，这里按category字段排序
            return goals.sorted { $0.category < $1.category }
        }
    }
    
    // 根据排序选项对目标进行排序
    private func sortGoals(_ goals: [Goal]) -> [Goal] {
        switch sortOption {
        case .name:
            return goals.sorted { $0.name < $1.name }
        case .createTime:
            return goals.sorted { $0.createTime < $1.createTime }
        case .modifyTime:
            return goals.sorted { $0.modifyTime < $1.modifyTime }
        case .visitTime:
            return goals.sorted { $0.visitTime < $1.visitTime }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    // 顶部导航栏
                    HStack {
                    // 删除左上角返回按钮
                    
                    Spacer()
                    
                    // 分段控制器
                    Picker("", selection: $selectedSegment) {
                        Text("人生").tag(0)
                        Text("年度").tag(1)
                        Text("短期").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: UIScreen.main.bounds.width * 0.6)
                    
                    Spacer()
                    
                    // 使用自定义视图替代复杂的Menu表达式
                    MenuButton {
                        // 视图切换选项
                        viewModeMenuContent
                        
                        Divider()
                        
                        // 分类子菜单
                        categoryMenuContent
                        
                        // 排序子菜单
                        sortMenuContent
                    }
                }
                
                // 年份选择器
                if selectedSegment == 1 {
                    HStack(spacing: 20) {
                        Button(action: { currentYear -= 1 }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(UIColor.systemBlue))
                        }
                        Text("\(currentYear)年")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        Button(action: { currentYear += 1 }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.systemBlue))
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 目标列表
                ScrollView {
                    VStack(spacing: 16) {
                        // 类别标题
                        HStack {
                            Text(selectedSegment == 0 ? "类别1" : (selectedSegment == 1 ? "年初" : "类别1"))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            Spacer()
                        }
                        .padding(.horizontal, 16) // 统一边距
                        .padding(.top, 12)
                        
                        // 根据视图模式显示不同的布局
                        if viewMode == .gallery {
                            // 画廊视图 - 网格布局，每行两个
                            let screenWidth = UIScreen.main.bounds.width
                            let cardWidth = (screenWidth - 16*2 - 16) / 2 // 屏幕宽度减去左右边距和中间间距
                            
                            LazyVGrid(columns: [
                                GridItem(.fixed(cardWidth), spacing: 16),
                                GridItem(.fixed(cardWidth), spacing: 16)
                            ], spacing: 24) { // 增加垂直间距，避免与类别标题重叠
                                ForEach(selectedSegment == 1 ? processedYearGoals : processedPeriodGoals) { goal in
                                    GoalCard(goal: goal)
                                }
                            }
                            .padding(.horizontal, 16) // 统一边距
                        } else {
                            // 列表视图
                            LazyVStack(spacing: 12) {
                                ForEach(selectedSegment == 1 ? processedYearGoals : processedPeriodGoals) { goal in
                                    GoalListItem(goal: goal)
                                }
                            }
                            .padding(.horizontal, 16) // 统一边距
                        }
                        
                        // 类别标题
                        HStack {
                            Text(selectedSegment == 0 ? "类别2" : (selectedSegment == 1 ? "年中" : "类别2"))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            Spacer()
                        }
                        .padding(.horizontal, 16) // 统一边距
                        .padding(.top, 12)
                        
                        // 根据视图模式显示不同的布局
                        if viewMode == .gallery {
                            // 画廊视图 - 网格布局，每行两个
                            let screenWidth = UIScreen.main.bounds.width
                            let cardWidth = (screenWidth - 16*2 - 16) / 2 // 屏幕宽度减去左右边距和中间间距
                            
                            LazyVGrid(columns: [
                                GridItem(.fixed(cardWidth), spacing: 16),
                                GridItem(.fixed(cardWidth), spacing: 16)
                            ], spacing: 24) { // 增加垂直间距，避免与类别标题重叠
                                ForEach(selectedSegment == 1 ? processedYearGoals : processedPeriodGoals) { goal in
                                    GoalCard(goal: goal)
                                }
                            }
                            .padding(.horizontal, 16) // 统一边距
                        } else {
                            // 列表视图
                            LazyVStack(spacing: 12) {
                                ForEach(selectedSegment == 1 ? processedYearGoals : processedPeriodGoals) { goal in
                                    GoalListItem(goal: goal)
                                }
                            }
                            .padding(.horizontal, 16) // 统一边距
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.bottom)
            
            // 添加目标的浮动按钮 - 完全参考iOS备忘录应用样式
            Button(action: {
                showAddGoalSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemBlue))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showAddGoalSheet) {
            AddGoalView(isPresented: $showAddGoalSheet, addedGoals: $addedGoals, selectedSegment: $selectedSegment)
        }
    }
}

// 目标卡片视图
struct GoalCard: View {
    let goal: Goal
    
    // 获取卡片宽度
    private var cardWidth: CGFloat {
        return (UIScreen.main.bounds.width - 16*2 - 16) / 2
    }
    
    // 获取进度颜色
    private var progressColor: Color {
        if goal.progress > 0.7 {
            return Color(UIColor.systemGreen)
        } else if goal.progress > 0.3 {
            return Color(UIColor.systemOrange)
        } else {
            return Color(UIColor.systemRed)
        }
    }
    
    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            ZStack(alignment: .topLeading) {
                // 卡片背景
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.13), radius: 10, x: 0, y: 6)
                
                // 内容容器
                VStack(alignment: .leading, spacing: 0) {
                    // 顶部区域：背景图片和渐变
                    ZStack(alignment: .topTrailing) {
                        // 背景图片或默认渐变背景
                        if let imageName = goal.backgroundImage, let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 80)
                                .clipped()
                        } else {
                            // 默认渐变背景
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 80)
                        }
                        
                        // 进度环形指示器
                        ZStack {
                            Circle()
                                .fill(Color(UIColor.systemBackground))
                                .frame(width: 36, height: 36)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Circle()
                                .stroke(Color(UIColor.systemGray5), lineWidth: 3)
                                .frame(width: 30, height: 30)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(goal.progress))
                                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 30, height: 30)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(goal.progress * 100))%")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.label))
                        }
                        .frame(width: 36, height: 36)
                        .padding(8)
                    }
                    .frame(width: cardWidth)
                    
                    // 中间区域：目标标题和描述
                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.label))
                            .lineLimit(1)
                        Text(goal.description)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        // 标签
                        if !goal.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(goal.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.13))
                                        .foregroundColor(Color.blue)
                                        .cornerRadius(10)
                                }
                            }
                            .frame(height: 20)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    
                    // 底部区域：子任务列表
                    VStack(alignment: .leading, spacing: 4) {
                        // 子任务标题
                        HStack {
                            Text("子目标")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            Spacer()
                            
                            // 完成数量
                            Text("\(goal.tasks.filter { $0.isCompleted }.count)/\(goal.tasks.count)")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        
                        // 子任务列表
                        ForEach(goal.tasks.prefix(2)) { task in
                            Button(action: {
                                // 这里需要修改task的isCompleted状态
                                // 由于Goal和Task是结构体且属性是let，这里只是UI演示
                                // 实际应用中需要通过ViewModel或状态管理来更新
                            }) {
                                HStack(spacing: 8) {
                                    // 圆形复选框 - 现代风格
                                    ZStack {
                                        Circle()
                                            .stroke(task.isCompleted ? progressColor : Color(UIColor.systemGray3), lineWidth: 1.5)
                                            .frame(width: 16, height: 16)
                                        
                                        if task.isCompleted {
                                            Circle()
                                                .fill(progressColor)
                                                .frame(width: 16, height: 16)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // 任务标题
                                    Text(task.title)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(task.isCompleted ? Color(UIColor.tertiaryLabel) : Color(UIColor.label))
                                        .strikethrough(task.isCompleted)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // 如果有更多任务，显示"更多"提示
                        if goal.tasks.count > 2 {
                            Text("还有\(goal.tasks.count - 2)个任务...")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.top, 2)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
            .frame(width: cardWidth, height: 224)
        }
        .buttonStyle(PlainButtonStyle()) // 移除导航链接的默认样式
    }
}

// 列表视图中的目标项
struct GoalListItem: View {
    let goal: Goal
    
    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            HStack(alignment: .center, spacing: 16) {
                // 左侧进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(goal.progress))
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: -90))
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.heavy)
                }
                .frame(width: 50, height: 50)
                
                // 右侧内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(goal.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                    
                    // 标签
                    if !goal.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(goal.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10))
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(Color.blue)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 20)
                    }
                }
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle()) // 移除导航链接的默认样式
    }
}

// 视图模式枚举
enum ViewMode {
    case gallery // 画廊视图
    case list    // 列表视图
}

// 分类选项枚举
enum CategoryOption {
    case time  // 按时间分类
    case type  // 按类型分类
}

// 排序选项枚举
enum SortOption {
    case name       // 按名称排序
    case createTime // 按创建时间排序
    case modifyTime // 按修改时间排序
    case visitTime  // 按访问时间排序
}

// 数据模型
struct Goal: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let progress: Double
    let tasks: [Task]
    let backgroundImage: String? // 背景图片名称，nil表示使用默认白色背景
    
    // 新增属性
    let tags: [String]
    let upperProject: [String]
    let subProject: [String]
    let recordNum: Int
    let category: String
    let createTime: Date
    let modifyTime: Date
    let visitTime: Date
}

struct Task: Identifiable {
    let id: Int
    let title: String
    var isCompleted: Bool
}

// 添加目标的表单视图
struct AddGoalView: View {
    @Binding var isPresented: Bool
    @Binding var addedGoals: [Goal]
    @Binding var selectedSegment: Int
    
    // 表单字段
    @State private var goalName = ""
    @State private var goalDescription = ""
    @State private var selectedCategory = "技能提升"
    @State private var tags = ""
    
    // 可选类别
    private let categories = ["技能提升", "健康管理", "知识获取", "休闲娱乐", "其他"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("目标信息")) {
                    TextField("目标名称", text: $goalName)
                    
                    TextField("目标描述", text: $goalDescription)
                        .frame(height: 80)
                    
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("标签 (用逗号分隔)", text: $tags)
                }
                
                Section {
                    Button(action: {
                        // 创建新目标的逻辑
                        let newGoal = Goal(
                            id: UUID(),
                            name: goalName,
                            description: goalDescription,
                            progress: 0.0,
                            tasks: [],
                            backgroundImage: nil,
                            tags: tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) },
                            upperProject: [],
                            subProject: [],
                            recordNum: 0,
                            category: selectedCategory,
                            createTime: Date(),
                            modifyTime: Date(),
                            visitTime: Date()
                        )
                        
                        // 将新目标添加到addedGoals数组
                        addedGoals.append(newGoal)
                        
                        // 切换到短期目标分段
                        selectedSegment = 2
                        
                        isPresented = false
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationBarTitle("添加目标", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    // 创建新目标的逻辑
                    let newGoal = Goal(
                        id: UUID(),
                        name: goalName,
                        description: goalDescription,
                        progress: 0.0,
                        tasks: [],
                        backgroundImage: nil,
                        tags: tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) },
                        upperProject: [],
                        subProject: [],
                        recordNum: 0,
                        category: selectedCategory,
                        createTime: Date(),
                        modifyTime: Date(),
                        visitTime: Date()
                    )
                    
                    // 将新目标添加到addedGoals数组
                    addedGoals.append(newGoal)
                    
                    // 切换到短期目标分段
                    selectedSegment = 2
                    
                    isPresented = false
                }
            )
        }
    }
}

#Preview {
    GoalView()
}

// MARK: - 自定义菜单按钮
struct MenuButton<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Menu {
            content
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundColor(Color(UIColor.systemBlue))
                .padding(.trailing, 8) // 添加右侧留白
        }
    }
}
