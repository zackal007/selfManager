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
// 导入共享组件，包含FilterChip

// 目标优先级枚举
enum GoalImportance: Int, CaseIterable {
    case low = 1      // 低
    case medium = 2   // 中
    case high = 3     // 高
    case critical = 4 // 关键
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "关键"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return Color.gray
        case .medium: return Color.blue
        case .high: return Color.orange
        case .critical: return Color.red
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "minus.circle.fill"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// Goal扩展，添加优先级计算属性
extension Goal {
    var goalImportance: GoalImportance {
        return GoalImportance(rawValue: importance) ?? .medium
    }
}

// 瀑布流布局组件
struct WaterfallLayout<Content: View>: View {
    let items: [Goal]
    let columns: Int
    let spacing: CGFloat
    let geometry: GeometryProxy
    let content: (Goal, CGFloat) -> Content
    
    init(items: [Goal], columns: Int = 2, spacing: CGFloat = 16, geometry: GeometryProxy, @ViewBuilder content: @escaping (Goal, CGFloat) -> Content) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.geometry = geometry
        self.content = content
    }
    
    var body: some View {
        let cardWidth = (geometry.size.width - CGFloat(columns + 1) * spacing) / CGFloat(columns)
        
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(itemsForColumn(columnIndex), id: \.id) { item in
                        content(item, cardWidth)
                    }
                }
            }
        }
        .padding(.horizontal, spacing)
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [Goal] {
        return items.enumerated().compactMap { index, item in
            index % columns == columnIndex ? item : nil
        }
    }
}

// 使用SharedComponents.swift中的ScaleButtonStyle

struct GoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { $0.isDeleted == false }, 
           sort: \Goal.createTime, order: .reverse) private var allGoals: [Goal]
    
    // 分段控制器选择
    @State private var selectedSegment = 0
    @State private var selectedGoalType: GoalType? = nil
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 导航管理器
    @StateObject private var navigationManager = NavigationManager.shared
    
    // 初始化方法，接收selectedTab绑定
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    // 视图模式：画廊视图或列表视图
    @State private var viewMode: ViewMode = .gallery
    
    // 分类和排序选项
    @State private var categoryOption: CategoryOption = .time
    @State private var sortOption: SortOption = .name
    @State private var sortAscending: Bool = true // 排序方向：true为升序，false为降序
    
    // 显示菜单
    @State private var showMenu = false
    
    // 添加目标的状态变量
    @State private var showAddGoalSheet = false
    
    // 回收站相关状态变量
    @State private var showTrashView = false
    
    // 搜索相关状态变量
    @State private var showSearchBar = false
    @State private var searchText = ""
    @State private var isSearching = false
    
    // 刷新目标数据的状态变量
    @State private var refreshGoals = false
    
    // 目标类型相关状态变量
    @State private var goalTypes: [GoalType?] = [nil] + GoalType.allCases.map { $0 as GoalType? }
    @State private var currentGoalTypeIndex = 0
    
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
            // 排序选项子菜单
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
                
                Button(action: {
                    sortOption = .importance
                }) {
                    Text("优先级")
                    if sortOption == .importance {
                        Image(systemName: "checkmark")
                    }
                }
            } label: {
                Text("排序字段")
            }
            
            // 排序方向子菜单
            Menu {
                Button(action: {
                    sortAscending = true
                }) {
                    Text("升序")
                    if sortAscending {
                        Image(systemName: "checkmark")
                    }
                }
                
                Button(action: {
                    sortAscending = false
                }) {
                    Text("降序")
                    if !sortAscending {
                        Image(systemName: "checkmark")
                    }
                }
            } label: {
                Text("排序方向")
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
    
    // 搜索过滤后的目标
    private var filteredGoals: [Goal] {
        if searchText.isEmpty {
            return allGoals
        } else {
            return allGoals.filter { goal in
                goal.name.localizedCaseInsensitiveContains(searchText) ||
                goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    // 根据分类和排序选项处理后的目标数据
    private var processedYearGoals: [Goal] {
        let goals = isSearching ? filteredGoals : allGoals
        let yearGoals = goals.filter { goal in
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
        let goals = isSearching ? filteredGoals : allGoals
        let periodGoals = goals.filter { goal in
            return goal.goalType == .shortTerm
        }
        return sortGoals(periodGoals)
    }
    
    private var processedLifeGoals: [Goal] {
        let goals = isSearching ? filteredGoals : allGoals
        let lifeGoals = goals.filter { goal in
            return goal.goalType == .life
        }
        return sortGoals(categorizeGoals(lifeGoals))
    }
    
    private var processedHabitGoals: [Goal] {
        let goals = isSearching ? filteredGoals : allGoals
        let habitGoals = goals.filter { goal in
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
            return sortAscending ? 
                goals.sorted { $0.name < $1.name } : 
                goals.sorted { $0.name > $1.name }
        case .createTime:
            return sortAscending ? 
                goals.sorted { $0.createTime < $1.createTime } : 
                goals.sorted { $0.createTime > $1.createTime }
        case .modifyTime:
            return sortAscending ? 
                goals.sorted { $0.modifyTime < $1.modifyTime } : 
                goals.sorted { $0.modifyTime > $1.modifyTime }
        case .visitTime:
            return sortAscending ? 
                goals.sorted { $0.visitTime < $1.visitTime } : 
                goals.sorted { $0.visitTime > $1.visitTime }
        case .importance:
            return sortAscending ? 
                goals.sorted { $0.importance < $1.importance } : 
                goals.sorted { $0.importance > $1.importance }
        }
    }
    
    // MARK: - 滑动手势处理
    
    // 获取所有可用的目标类型（包括"全部"选项）
    private var allGoalTypes: [GoalType?] {
        return [nil] + GoalType.allCases
    }
    
    // 获取当前选中类型的索引
    private var currentTypeIndex: Int {
        return allGoalTypes.firstIndex(where: { $0 == selectedGoalType }) ?? 0
    }
    
    // 切换到下一个目标类型
    private func switchToNextType() {
        let nextIndex = (currentTypeIndex + 1) % allGoalTypes.count
        switchToType(at: nextIndex)
    }
    
    // 切换到上一个目标类型
    private func switchToPreviousType() {
        let previousIndex = currentTypeIndex == 0 ? allGoalTypes.count - 1 : currentTypeIndex - 1
        switchToType(at: previousIndex)
    }
    
    // 切换到指定索引的目标类型
    private func switchToType(at index: Int) {
        guard index >= 0 && index < allGoalTypes.count else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedGoalType = allGoalTypes[index]
            
            // 更新selectedSegment以保持一致性
            if let type = selectedGoalType {
                switch type {
                case .life:
                    selectedSegment = 0
                case .yearly:
                    selectedSegment = 1
                case .shortTerm:
                    selectedSegment = 2
                case .habit:
                    selectedSegment = 3
                }
            } else {
                selectedSegment = 0
            }
        }
    }
    
    // 同步selectedGoalType变化到currentGoalTypeIndex
    private func syncGoalTypeIndex() {
        if let index = goalTypes.firstIndex(of: selectedGoalType) {
            currentGoalTypeIndex = index
        }
    }
    

    
    var body: some View { 
        ZStack {
            // 主视图
            NavigationStack(path: navigationManager.getNavigationPath(for: 1)) {
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
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSearchBar.toggle()
                                if !showSearchBar {
                                    searchText = ""
                                    isSearching = false
                                }
                            }
                        }) {
                            Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
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
                            // 刷新目标数据按钮
                            Button(action: {
                                // 重新加载目标数据
                                // 通过切换一个刷新状态变量强制刷新视图
                                refreshGoals.toggle()
                            }) {
                                Label("刷新目标", systemImage: "arrow.clockwise")
                            }
                            Divider()
                            // 回收站选项
                            Button(action: {
                                showTrashView = true
                            }) {
                                Label("回收站", systemImage: "trash")
                            }
                            Divider()
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
                    
                    // 目标类型筛选器
                    VStack(alignment: .leading, spacing: 8) {
                       ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // 全部选项
                                FilterChip(title: "全部", isSelected: selectedGoalType == nil) {
                                    selectedGoalType = nil
                                    selectedSegment = 0
                                    syncGoalTypeIndex()
                                }
                                
                                // 各种目标类型
                                ForEach(GoalType.allCases, id: \.self) { type in
                                    FilterChip(title: type.rawValue, isSelected: selectedGoalType == type) {
                                        selectedGoalType = type
                                        syncGoalTypeIndex()
                                        // 根据选择的目标类型设置selectedSegment
                                        switch type {
                                        case .life:
                                            selectedSegment = 0
                                        case .yearly:
                                            selectedSegment = 1
                                        case .shortTerm:
                                            selectedSegment = 2
                                        case .habit:
                                            selectedSegment = 3
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
                    // 搜索栏
                    if showSearchBar {
                        searchBarView
                    }
                
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
                
                // 目标列表 - 使用TabView实现丝滑滑动
                GeometryReader { geometry in
                    TabView(selection: $currentGoalTypeIndex) {
                        ForEach(goalTypes.indices, id: \.self) { index in
                            ScrollView {
                                VStack(spacing: 16) {
                                    // 移除了分类标题
                                    Spacer().frame(height: 8)
                                    .padding(.top, 8)
                                
                                    // 根据视图模式显示不同的布局
                                    if viewMode == .gallery {
                                        switch goalTypes[index] {
                                        case .life:
                                            LifeGoalGalleryView(goals: processedLifeGoals, geometry: geometry)
                                        case .yearly:
                                            YearGoalGalleryView(goals: processedYearGoals, geometry: geometry)
                                        case .shortTerm:
                                            ShortTermGoalGalleryView(goals: processedPeriodGoals, geometry: geometry)
                                        case .habit:
                                            HabitGoalGalleryView(goals: processedHabitGoals, geometry: geometry)
                                        case nil:
                                            AllGoalGalleryView(goals: sortGoals(isSearching ? filteredGoals : allGoals), geometry: geometry)
                                        }
                                    } else {
                                        switch goalTypes[index] {
                                        case .life:
                                            LifeGoalListView(goals: processedLifeGoals)
                                        case .yearly:
                                            YearGoalListView(goals: processedYearGoals)
                                        case .shortTerm:
                                            ShortTermGoalListView(goals: processedPeriodGoals)
                                        case .habit:
                                            HabitGoalListView(goals: processedHabitGoals)
                                        case nil:
                                            AllGoalListView(goals: sortGoals(isSearching ? filteredGoals : allGoals))
                                        }
                                    }
                                }
                                .padding(.bottom, 16)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentGoalTypeIndex) { newIndex in
                        // 同步更新selectedGoalType
                        selectedGoalType = goalTypes[newIndex]
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
                            .padding(.horizontal, 20)
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
        .sheet(isPresented: $showTrashView) {
            TrashView()
        }
        .onChange(of: searchText) { _, newValue in
            isSearching = !newValue.isEmpty
        }
        .overlay(
            // 搜索状态指示器
            Group {
                if isSearching {
                    VStack {
                        HStack {
                            Text("搜索: \"\(searchText)\"")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(15)
                            
                            Button("清除") {
                                searchText = ""
                                isSearching = false
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                }
            }
        )
    }
    }
    
    // MARK: - Private Methods
    
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
    
    // 搜索栏视图
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("搜索目标...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    isSearching = true
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearching = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func goalsForSelectedSegment(category: Int) -> [Goal] {
        // 当selectedGoalType为nil时，返回所有目标
        if selectedGoalType == nil {
            // 返回所有类型的目标
            let goals = isSearching ? filteredGoals : allGoals
            return sortGoals(goals)
        }
        
        // 否则按分段控制器选择返回特定类型的目标
        switch selectedSegment {
        case 0:
            return processedLifeGoals
        case 1:
            return processedYearGoals
        case 2:
            return processedPeriodGoals
        case 3:
            return processedHabitGoals
        default:
            return []
        }
    }
}

struct LifeGoalGalleryView: View {
    let goals: [Goal]
    let geometry: GeometryProxy
    var body: some View {
        WaterfallLayout(items: goals, columns: 2, spacing: 16, geometry: geometry) { goal, cardWidth in
            GoalCard(goal: goal, cardWidth: cardWidth)
        }
    }
}
struct YearGoalGalleryView: View {
    let goals: [Goal]
    let geometry: GeometryProxy
    var body: some View {
        WaterfallLayout(items: goals, columns: 2, spacing: 16, geometry: geometry) { goal, cardWidth in
            GoalCard(goal: goal, cardWidth: cardWidth)
        }
    }
}
struct ShortTermGoalGalleryView: View {
    let goals: [Goal]
    let geometry: GeometryProxy
    var body: some View {
        WaterfallLayout(items: goals, columns: 2, spacing: 16, geometry: geometry) { goal, cardWidth in
            GoalCard(goal: goal, cardWidth: cardWidth)
        }
    }
}
struct HabitGoalGalleryView: View {
    let goals: [Goal]
    let geometry: GeometryProxy
    var body: some View {
        WaterfallLayout(items: goals, columns: 2, spacing: 16, geometry: geometry) { goal, cardWidth in
            GoalCard(goal: goal, cardWidth: cardWidth)
        }
    }
}
struct AllGoalGalleryView: View {
    let goals: [Goal]
    let geometry: GeometryProxy
    var body: some View {
        WaterfallLayout(items: goals, columns: 2, spacing: 16, geometry: geometry) { goal, cardWidth in
            SimplifiedGoalCard(goal: goal, cardWidth: cardWidth)
        }
    }
}
// 列表视图拆分组件
struct LifeGoalListView: View {
    let goals: [Goal]
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(goals) { goal in
                GoalListItem(goal: goal)
            }
        }
        .padding(.horizontal, 12)
    }
}
struct YearGoalListView: View {
    let goals: [Goal]
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(goals) { goal in
                GoalListItem(goal: goal)
            }
        }
        .padding(.horizontal, 12)
    }
}
struct ShortTermGoalListView: View {
    let goals: [Goal]
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(goals) { goal in
                GoalListItem(goal: goal)
            }
        }
        .padding(.horizontal, 12)
    }
}
struct HabitGoalListView: View {
    let goals: [Goal]
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(goals) { goal in
                GoalListItem(goal: goal)
            }
        }
        .padding(.horizontal, 12)
    }
}
struct AllGoalListView: View {
    let goals: [Goal]
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(goals) { goal in
                SimplifiedGoalListItem(goal: goal)
            }
        }
        .padding(.horizontal, 12)
    }
}
// 目标卡片视图

struct GoalCard: View {
    let goal: Goal
    var cardWidth: CGFloat
    @State private var nameAndDescHeight: CGFloat = 0
    
    // 初始化方法，提供默认值
    init(goal: Goal, cardWidth: CGFloat? = nil) {
        self.goal = goal
        self.cardWidth = cardWidth ?? 160
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
    // 优先级竖线颜色
    private var priorityLineColor: Color {
        switch goal.goalImportance {
        case .low:
            return Color.blue
        case .medium:
            return Color.orange
        case .high, .critical:
            return Color.red
        }
    }
    // 获取应用文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            ZStack {
                // 背景图片或默认渐变背景 - 置于底层
                if let imageName = goal.backgroundImage {
                    // 首先尝试从应用资源中加载预设图片
                    if let uiImage = UIImage(named: imageName) {
                        // 预设背景图片 - 占满整个卡片
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .opacity(0.7) // 降低不透明度，使内容更易读
                    } else {
                        // 尝试从文档目录加载用户自定义图片
                        let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
                        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                            // 用户自定义背景图片 - 占满整个卡片
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .opacity(0.7) // 降低不透明度，使内容更易读
                                // 添加模糊效果，提高可读性
                                .blur(radius: 1.5)
                        }
                    }
                } else {
                    // 默认渐变背景 - 占满整个卡片
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: cardWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // 添加半透明覆盖层，使内容更易读
                Rectangle()
                    .fill(Color(UIColor.systemBackground).opacity(0.5))
                    .frame(width: cardWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // 卡片阴影
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .shadow(color: Color(UIColor.label).opacity(0.15), radius: 8, x: 0, y: 4)
                
                // 内容容器 - 所有元素放在同一图层，向左上角对齐
                VStack(alignment: .leading, spacing: 8) {
                    Spacer().frame(height: 18) // 优雅的顶部内边距
                    
                    // 顶部区域：优先级指示器和目标信息
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        // 优先级圆点指示器 - 优化设计
                        Circle()
                            .fill(goal.goalImportance.color)
                            .frame(width: 9, height: 9)
                            .padding(.top, 1)
                            .padding(.leading, 12) // 向右移动避免与边缘重叠
                        // 目标名称和描述 - 优化字体和间距
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(UIColor.label))
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        if !goal.goalDescription.isEmpty {
                            Text(goal.goalDescription)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        }
                    }
                    
                    // 现代化进度条设计 - 参考iOS原生风格
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景轨道
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor.systemGray5))
                                .frame(height: 6)
                            
                            // 进度条 - 使用系统标准动画
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: max(4, geometry.size.width * CGFloat(goal.progress)), height: 6)
                                .animation(.easeOut(duration: 0.3), value: goal.progress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 6)
                    .padding(.horizontal, 20)
                    
                    // 标签区域
                    if !goal.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(goal.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.08))
                                        .foregroundColor(Color.blue)
                                        .cornerRadius(12)
                                }
                                if goal.tags.count > 3 {
                                    Text("+\(goal.tags.count - 3)")
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.gray.opacity(0.1))
                                        .foregroundColor(Color.gray)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 24)
                    }
                    
                    // 子任务区域
                    if !goal.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            // 子任务标题
                            HStack {
                                Text("子任务")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                
                                Spacer()
                                
                                // 完成数量
                                Text("\(goal.tasks.filter { $0.isCompleted }.count)/\(goal.tasks.count)")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                            }
                            
                            // 子任务列表 - 最多显示2个，高度固定
                            VStack(spacing: 6) {
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
                                                .truncationMode(.tail) // 确保文本过长时正确截断
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(height: goal.tasks.count == 1 ? 24 : 52)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 20)
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.7))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    // 添加底部空白，推动内容向上
                    Spacer()
                }
                .frame(width: cardWidth, alignment: .topLeading) // 确保内容容器占满整个卡片宽度并向左上角对齐
            }
            .frame(width: cardWidth) // 卡片宽度固定，高度自适应
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
                // 优先级指示器
                ZStack {
                    Circle()
                        .fill(goal.goalImportance.color.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: goal.goalImportance.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(goal.goalImportance.color)
                }
                .frame(width: 28, height: 28)
                
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
        
        // 目标描述为可选项，不再进行空值检查
        
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

// 简化版目标卡片视图 - 只显示目标名称和类型
struct SimplifiedGoalCard: View {
    let goal: Goal
    var cardWidth: CGFloat
    
    // 初始化方法，提供默认值
    init(goal: Goal, cardWidth: CGFloat? = nil) {
        self.goal = goal
        self.cardWidth = cardWidth ?? 160 // 使用固定宽度代替屏幕宽度计算
    }
    
    // 获取应用文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            ZStack {
                // 背景图片或默认渐变背景 - 置于底层
                if let imageName = goal.backgroundImage {
                    // 首先尝试从应用资源中加载预设图片
                    if let uiImage = UIImage(named: imageName) {
                        // 预设背景图片 - 占满整个卡片
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .opacity(0.7) // 降低不透明度，使内容更易读
                    } else {
                        // 尝试从文档目录加载用户自定义图片
                        let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
                        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                            // 用户自定义背景图片 - 占满整个卡片
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .opacity(0.7) // 降低不透明度，使内容更易读
                            // 添加模糊效果，提高可读性
                                .blur(radius: 1.5)
                        }
                    }
                } else {
                    // 默认渐变背景 - 占满整个卡片
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: cardWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // 添加半透明覆盖层，使内容更易读
                Rectangle()
                    .fill(Color(UIColor.systemBackground).opacity(0.5))
                    .frame(width: cardWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // 卡片阴影
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .shadow(color: Color(UIColor.label).opacity(0.15), radius: 8, x: 0, y: 4)
                
                // 内容容器 - 只显示目标名称和类型
                // 优化顶部内边距和间距
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 16)
                    
                    // 目标名称
                    Text(goal.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(2)
                        .padding(.top, 16)
                    
                    // 目标类型
                    Text(goal.goalType.rawValue)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                        .padding(.bottom, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(width: cardWidth, alignment: .topLeading) // 确保内容容器占满整个卡片宽度并向左上角对齐
            }
            .frame(width: cardWidth) // 移除固定卡片高度
        }
        .buttonStyle(PlainButtonStyle()) // 移除导航链接的默认样式
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, GoalTask.self, configurations: config)
    
    GoalView(selectedTab: .constant(0))
        .modelContainer(container)
}

// 简化版列表视图中的目标项 - 只显示目标名称和类型
struct SimplifiedGoalListItem: View {
    let goal: Goal
    
    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            HStack(alignment: .center, spacing: 16) {
                // 左侧背景色块，用于视觉区分
                RoundedRectangle(cornerRadius: 8)
                    .fill(goal.goalType.color.opacity(0.2))
                    .frame(width: 8, height: 50)
                
                // 右侧内容
                VStack(alignment: .leading, spacing: 4) {
                    // 目标名称
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    // 目标类型
                    Text(goal.goalType.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
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
