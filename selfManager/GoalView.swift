//
//  GoalView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import UIKit
import Foundation
import SwiftData

// 使用SharedComponents.swift中的ScaleButtonStyle

struct GoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createTime, order: .reverse) private var allGoals: [Goal]
    
    // 分段控制器选择
    @State private var selectedSegment = 0
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 初始化方法，接收selectedTab绑定
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
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
                Label("卡片视图", systemImage: "square.grid.2x2")
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
                Text("时间")
                if categoryOption == .time {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                categoryOption = .type
            }) {
                Text("类型")
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
                Text("名称")
                if sortOption == .name {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .createTime
            }) {
                Text("创建时间")
                if sortOption == .createTime {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .modifyTime
            }) {
                Text("修改时间")
                if sortOption == .modifyTime {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .visitTime
            }) {
                Text("访问时间")
                if sortOption == .visitTime {
                    Image(systemName: "checkmark")
                }
            }
        } label: {
            Label("排序", systemImage: "arrow.up.arrow.down")
        }
    }
    
    // 初始化示例数据的标志
    @State private var hasInitializedData = false
    
    // 当前年份
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var yearChangeAnimation = false // 用于年份变化动画
    @State private var showYearChangeToast = false // 用于显示年份变化提示
    @State private var yearChangeDirection = "" // 用于记录年份变化方向
    
    // 根据分类和排序选项处理后的目标数据
    private var processedYearGoals: [Goal] {
        let yearGoals = allGoals.filter { goal in
            // 首先按目标类型筛选
            guard goal.goalType == .yearly else { return false }
            
            // 然后按截止日期年份筛选
            if let dueDate = goal.dueDate {
                let dueDateYear = Calendar.current.component(.year, from: dueDate)
                return dueDateYear == currentYear
            }
            return false // 如果没有截止日期，则不显示
        }
        return sortGoals(categorizeGoals(yearGoals))
    }
    
    private var processedPeriodGoals: [Goal] {
        let periodGoals = allGoals.filter { goal in
            return goal.goalType == .shortTerm
        }
        return sortGoals(periodGoals)
    }
    
    private var processedLifeGoals: [Goal] {
        let lifeGoals = allGoals.filter { goal in
            return goal.goalType == .life
        }
        return sortGoals(categorizeGoals(lifeGoals))
    }
    
    private var processedHabitGoals: [Goal] {
        let habitGoals = allGoals.filter { goal in
            return goal.goalType == .habit
        }
        return sortGoals(categorizeGoals(habitGoals))
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
        ZStack {
            // 主视图
            NavigationView {
                VStack(spacing: 0) {
                    
                    // 顶部标题栏
                    HStack {
                        Text("目标")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 搜索按钮
                        Button(action: {
                            // 搜索功能的实现将在后续添加
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // 添加目标按钮
                        Button(action: {
                            showAddGoalSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // 使用自定义视图替代复杂的Menu表达式
                        MenuButton {
                            
                            // 视图切换选项
                            Group {
                                viewModeMenuContent
                            }
                            
                            Divider()
                            
                            // 分类子菜单
                            Group {
                                categoryMenuContent
                            }
                            
                            // 排序子菜单
                            Group {
                                sortMenuContent
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // 分段控制器
                    Picker("目标类型", selection: $selectedSegment) {
                        Text("人生").tag(0)
                        Text("年度").tag(1)
                        Text("短期").tag(2)
                        Text("习惯").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                
                // 年份选择器
                if selectedSegment == 1 {
                    HStack(spacing: 16) {
                        Spacer()
                        
                        Button(action: {
                             withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                 yearChangeAnimation = true
                                 currentYear -= 1
                                 yearChangeDirection = "减少"
                             }
                             // 使用Timer替代DispatchQueue以避免多线程问题
                             Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                 yearChangeAnimation = false
                                 showYearChangeToast = true
                                 
                                 // 嵌套Timer替代第二个DispatchQueue
                                 Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                     showYearChangeToast = false
                                 }
                             }
                         }) {
                             Image(systemName: "chevron.left.circle.fill")
                                 .font(.system(size: 22))
                                 .foregroundColor(.blue)
                                 .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                         }
                         .buttonStyle(ScaleButtonStyle())
                        
                        Text("\(currentYear)年")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 80)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .scaleEffect(yearChangeAnimation ? 0.9 : 1)
                            .opacity(yearChangeAnimation ? 0.7 : 1)
                            .rotationEffect(Angle(degrees: yearChangeAnimation ? 2 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: yearChangeAnimation)
                        
                        Button(action: {
                             withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                 yearChangeAnimation = true
                                 currentYear += 1
                                 yearChangeDirection = "增加"
                             }
                             // 使用Timer替代DispatchQueue以避免多线程问题
                             Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                 yearChangeAnimation = false
                                 showYearChangeToast = true
                                 
                                 // 嵌套Timer替代第二个DispatchQueue
                                 Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                     showYearChangeToast = false
                                 }
                             }
                         }) {
                             Image(systemName: "chevron.right.circle.fill")
                                 .font(.system(size: 22))
                                 .foregroundColor(.blue)
                                 .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                         }
                         .buttonStyle(ScaleButtonStyle())
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color(.systemBackground).opacity(0.5))
                }
                
                // 目标列表
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 16) {
                            // 类别标题
                            HStack {
                                Text(getCategoryTitle(for: selectedSegment, category: 1))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                        
                        // 根据视图模式显示不同的布局
                        if viewMode == .gallery {
                            // 画廊视图 - 网格布局，每行两个
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) { // 减小垂直间距，使布局更紧凑
                                ForEach(goalsForSelectedSegment(category: 1)) { goal in
                                    GoalCard(goal: goal)
                                        .frame(height: 280) // 确保网格中的卡片高度一致
                                }
                            }
                            .padding(.horizontal, 12) // 统一边距
                        } else {
                            // 列表视图
                            LazyVStack(spacing: 12) {
                                ForEach(goalsForSelectedSegment(category: 1)) { goal in
                                    GoalListItem(goal: goal)
                                }
                            }
                            .padding(.horizontal, 12) // 统一边距
                        }
                        
                        // 类别标题
                        HStack {
                            Text(getCategoryTitle(for: selectedSegment, category: 2))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                            Spacer()
                        }
                        .padding(.horizontal, 16) // 统一边距
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // 根据视图模式显示不同的布局
                        if viewMode == .gallery {
                            // 画廊视图 - 网格布局，每行两个
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(goalsForSelectedSegment(category: 2)) { goal in
                                    GoalCard(goal: goal, cardWidth: (geometry.size.width - 40) / 2)
                                        .frame(height: 280)
                                }
                            }
                            .padding(.horizontal, 12) // 统一边距
                        } else {
                            // 列表视图
                            LazyVStack(spacing: 12) {
                                ForEach(goalsForSelectedSegment(category: 2)) { goal in
                                    GoalListItem(goal: goal)
                                }
                            }
                            .padding(.horizontal, 12) // 统一边距
                        }
                    }
                    .padding(.bottom, 16)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.bottom)
            
            // 年份变化提示
            if showYearChangeToast {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Text("已\(yearChangeDirection)到\(currentYear)年")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Spacer()
                    }
                    
                    Spacer().frame(height: 100)
                }
                .animation(.easeInOut, value: showYearChangeToast)
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showAddGoalSheet) {
                AddGoalView(isPresented: $showAddGoalSheet, selectedSegment: $selectedSegment)
            }
    }
    
    private func goalsForSelectedSegment(category: Int) -> [Goal] {
        let goals: [Goal]
        switch selectedSegment {
        case 0:
            goals = processedLifeGoals
        case 1:
            goals = processedYearGoals
        case 2:
            goals = processedPeriodGoals
        case 3:
            goals = processedHabitGoals
        default:
            goals = []
        }
        
        // 假设每个类别有两个分区
        let half = goals.count / 2
        if category == 1 {
            return Array(goals.prefix(half))
        } else {
            return Array(goals.suffix(goals.count - half))
        }
    }
    
    // 获取类别标题
    private func getCategoryTitle(for segment: Int, category: Int) -> String {
        switch segment {
        case 0: // 人生目标
            return category == 1 ? "长期规划" : "核心价值"
        case 1: // 年度目标
            return category == 1 ? "年初" : "年中"
        case 2: // 短期目标
            return category == 1 ? "进行中" : "待开始"
        case 3: // 习惯
            return category == 1 ? "日常习惯" : "培养中"
        default:
            return "类别\(category)"
        }
    }
}

// 目标卡片视图
struct GoalCard: View {
    let goal: Goal
    var cardWidth: CGFloat
    
    // 初始化方法，提供默认值
    init(goal: Goal, cardWidth: CGFloat? = nil) {
        self.goal = goal
        self.cardWidth = cardWidth ?? 160 // 使用固定宽度代替屏幕宽度计算
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
            ZStack {
                // 背景图片或默认渐变背景 - 置于底层
                if let imageName = goal.backgroundImage, let uiImage = UIImage(named: imageName) {
                    // 背景图片 - 占满整个卡片
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: 280) // 占满整个卡片高度
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .opacity(0.7) // 降低不透明度，使内容更易读
                } else {
                    // 默认渐变背景 - 占满整个卡片
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: cardWidth, height: 280) // 占满整个卡片高度
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // 添加半透明覆盖层，使内容更易读
                Rectangle()
                    .fill(Color(UIColor.systemBackground).opacity(0.5))
                    .frame(width: cardWidth, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // 卡片阴影
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .shadow(color: Color(UIColor.label).opacity(0.15), radius: 8, x: 0, y: 4)
                
                // 进度环形指示器 - 固定在右上角
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemBackground))
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(UIColor.label).opacity(0.15), radius: 3, x: 0, y: 2)
                    
                    Circle()
                        .stroke(Color(UIColor.systemGray5), lineWidth: 3.5)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(goal.progress))
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(width: 44, height: 44)
                .padding(12)
                .position(x: cardWidth - 34, y: 34) // 固定在右上角
                
                // 内容容器
                VStack(alignment: .leading, spacing: 0) {
                    // 设置VStack宽度为卡片宽度
                    ZStack(alignment: .topTrailing) {
                        
                        // 这里之前有重复的代码，已移除
                    }
                    // 确保ZStack占满整个卡片宽度
                    .frame(width: cardWidth, alignment: .center)
                    
                    // 中间区域：目标标题和描述
                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.label))
                            .lineLimit(1)
                        Text(goal.goalDescription)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        // 标签
                        if !goal.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(goal.tags.prefix(2), id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(Color.blue)
                                            .cornerRadius(10)
                                    }
                                    if goal.tags.count > 2 {
                                        Text("+\(goal.tags.count - 2)")
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.gray.opacity(0.1))
                                            .foregroundColor(Color.gray)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(height: 24)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // 底部区域：子任务列表
                    VStack(alignment: .leading, spacing: 6) {
                        // 子任务标题
                        HStack {
                            Text("子目标")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            Spacer()
                            
                            // 完成数量
                            Text("\(goal.tasks.filter { $0.isCompleted }.count)/\(goal.tasks.count)")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        
                        // 子任务列表
                        ForEach(goal.tasks.prefix(2)) { task in
                            Button(action: {
                                // 这里需要修改task的isCompleted状态
                                // 由于Goal和Task是结构体且属性是let，这里只是UI演示
                                // 实际应用中需要通过ViewModel或状态管理来更新
                            }) {
                                HStack(spacing: 10) {
                                    // 圆形复选框 - 现代风格
                                    ZStack {
                                        Circle()
                                            .stroke(task.isCompleted ? progressColor : Color(UIColor.systemGray3), lineWidth: 1.5)
                                            .frame(width: 18, height: 18)
                                        
                                        if task.isCompleted {
                                            Circle()
                                                .fill(progressColor)
                                                .frame(width: 18, height: 18)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // 任务标题
                                    Text(task.title)
                                        .font(.system(size: 13, design: .rounded))
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
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.top, 3)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
                .frame(width: cardWidth) // 确保内容容器占满整个卡片宽度
            }
            .frame(width: cardWidth, height: 280) // 固定卡片高度
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
                    
                    Text(goal.goalDescription)
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
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color(UIColor.label).opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle()) // 移除导航链接的默认样式
    }
}

// 数据模型已移至Models.swift文件

// 添加目标的表单视图
struct AddGoalView: View {
    @Binding var isPresented: Bool
    @Binding var selectedSegment: Int
    @Environment(\.modelContext) private var modelContext
    
    // 表单字段
    @State private var goalName = ""
    @State private var goalDescription = ""
    @State private var selectedCategory = "短期目标"
    @State private var tags = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    // 错误处理
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    // 成功提示
    @State private var showSuccessToast = false
    @State private var successMessage = ""
    
    // 可选类别
    private let categories = ["人生目标", "年度目标", "短期目标", "习惯"]
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    Section(header: Text("目标信息")) {
                        TextField("目标名称", text: $goalName)
                            .overlay(
                                goalName.isEmpty ? 
                                Text("目标名称不能为空").foregroundColor(.red).font(.caption) : nil,
                                alignment: .trailing
                            )
                        
                        TextField("目标描述", text: $goalDescription)
                            .frame(height: 80)
                        
                        Picker("类别", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        
                        TextField("标签 (用逗号分隔)", text: $tags)
                        
                        Toggle("设置截止日期", isOn: $hasDueDate)
                        
                        if hasDueDate {
                            DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date])
                        }
                    }
                }
                .navigationBarTitle("添加目标", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("取消") {
                        isPresented = false
                    },
                    trailing: Button("保存") {
                        validateAndSaveGoal()
                    }
                    .disabled(goalName.isEmpty)
                )
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("提示"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("确定"))
                    )
                }
            }
            
            // 成功提示Toast
            if showSuccessToast {
                VStack {
                    Spacer()
                    ToastView(message: successMessage, isSuccess: true)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showSuccessToast)
                .zIndex(1)
            }
        }
    }
    
    private func validateAndSaveGoal() {
        // 验证输入
        if goalName.isEmpty {
            errorMessage = "目标名称不能为空"
            showAlert = true
            return
        }
        
        if goalName.count < 2 {
            errorMessage = "目标名称至少需要2个字符"
            showAlert = true
            return
        }
        
        if goalDescription.isEmpty {
            errorMessage = "请添加目标描述"
            showAlert = true
            return
        }
        
        // 验证通过，保存目标
        saveGoal()
    }
    
    private func saveGoal() {
        // 创建新目标
        let newGoal = Goal(
            name: goalName,
            description: goalDescription,
            progress: 0.0,
            backgroundImage: nil,
            tags: tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) },
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: selectedCategory,
            goalType: GoalType.from(string: selectedCategory), // 根据选择的类别设置goalType
            dueDate: hasDueDate ? dueDate : nil
        )
        
        // 保存到数据库
        modelContext.insert(newGoal)
        
        do {
            try modelContext.save()
            
            // 根据新目标的类型切换分段
            switch newGoal.goalType {
            case .life:
                selectedSegment = 0
            case .yearly:
                selectedSegment = 1
            case .shortTerm:
                selectedSegment = 2
            case .habit:
                selectedSegment = 3
            }
            
            // 显示成功提示
            successMessage = "目标「\(goalName)」添加成功！"
            showSuccessToast = true
            
            // 延迟1.5秒后关闭表单，让用户有时间看到成功提示
            // 使用Timer替代DispatchQueue以避免多线程问题
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                isPresented = false
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, GoalTask.self, configurations: config)
    
    GoalView(selectedTab: .constant(0))
        .modelContainer(container)
}

// MARK: - 扩展RoundedRectangle以支持指定角的圆角
extension RoundedRectangle {
    func corners(_ corners: UIRectCorner, radius: CGFloat = 10) -> Path {
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 100, height: 100), 
                                byRoundingCorners: corners, 
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 使用SharedComponents.swift中的MenuButton
