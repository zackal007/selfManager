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
// 用于传递并测量顶栏高度的偏好键
struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
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
    @Query private var allUsers: [User]
    
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
    // 分段控制器状态
    @State private var selectedSegment = 0
    @State private var selectedGoalType: GoalType? = nil
    
    // 选中的标签页
    @Binding var selectedTab: Int
    
    // 导航管理器
    @StateObject private var navigationManager = NavigationManager.shared
    
    // 侧边栏使用全局管理器：移除本地状态，统一为全局覆盖层
    
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

    // "最近"筛选迁移相关状态变量（保持与 HomeView 一致）
    @State private var showGoalPopup = false
    @State private var goalFilterExpanded: Bool = UserDefaults.standard.bool(forKey: "goalFilterExpanded")
    // 弹窗内独立的类型筛选，避免切换页签
    @State private var popupSelectedGoalType: GoalType? = nil
    @State private var selectedImportance: GoalImportance? = nil
    @State private var selectedTags: Set<String> = []
    @State private var selectedYear: Int? = nil
    @State private var savedFilteredGoals: [Goal] = []
    
    // 刷新目标数据的状态变量
    @State private var refreshGoals = false
    
    // 目标类型相关状态变量
    @State private var goalTypes: [GoalType?] = [nil] + GoalType.allCases.map { $0 as GoalType? }
    @State private var currentGoalTypeIndex = 0
    // 顶栏动态高度（用于同步透明占位的高度，防止内容被遮挡）
    @State private var headerHeight: CGFloat = 120
    
    // 年份选择器状态变量
    @State private var showYearPicker = false
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var yearListBaseYear: Int = 0

    // “全部”页统一数据源：优先使用弹窗保存的筛选结果；否则按搜索文本回退
    private var allTabDisplayGoals: [Goal] {
        // 若存在筛选条件，则严格使用保存的筛选结果（即便为空）
        if (popupSelectedGoalType != nil) || (selectedImportance != nil) || (!searchText.isEmpty) || (!selectedTags.isEmpty) || (selectedYear != nil) {
            return savedFilteredGoals
        }
        // 无筛选条件时，根据是否正在搜索选择数据源
        return isSearching ? filteredGoals : allGoals
    }
    
    // MARK: - 菜单组件
    // 视图模式切换按钮 - 直接切换而非菜单
    private var viewModeMenuContent: some View {
        Button(action: {
            // 直接切换视图模式
            withAnimation {
                viewMode = viewMode == .gallery ? .list : .gallery
            }
        }) {
            Label(viewMode == .gallery ? "列表视图" : "卡片视图", 
                  systemImage: viewMode == .gallery ? "list.bullet" : "square.grid.2x2")
        }
    }
    
    // 排序菜单内容 - 点击字段切换正序/倒序
    // 排序选项按钮
    private func sortOptionButton(title: String, option: SortOption) -> some View {
        Button(action: {
            if sortOption == option {
                sortAscending.toggle()
            } else {
                sortOption = option
                sortAscending = true
            }
        }) {
            HStack {
                Text(title)
                Spacer()
                if sortOption == option {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12))
                }
            }
        }
    }
    
    private var sortMenuContent: some View {
        Menu {
            sortOptionButton(title: "名称", option: .name)
            sortOptionButton(title: "创建时间", option: .createTime)
            sortOptionButton(title: "修改时间", option: .modifyTime)
            sortOptionButton(title: "访问时间", option: .visitTime)
            sortOptionButton(title: "优先级", option: .importance)
            sortOptionButton(title: "进度", option: .progress)
        } label: {
            Label("排序", systemImage: "arrow.up.arrow.down")
        }
    }
    
    // 省略号菜单内容
    private var ellipsisMenuContent: some View {
        Menu {
            // 1. 视图模式切换选项
            Button(action: {
                // 直接切换视图模式
                withAnimation {
                    viewMode = viewMode == .gallery ? .list : .gallery
                }
            }) {
                Label(viewMode == .gallery ? "列表视图" : "卡片视图", 
                      systemImage: viewMode == .gallery ? "list.bullet" : "square.grid.2x2")
            }
            
            Divider()
            
            // 2. 排序选项子菜单
            sortMenuContent
            
            Divider()
            
            // 3. 回收站按钮
            Button(action: {
                showTrashView = true
            }) {
                Label("回收站", systemImage: "trash")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray5).opacity(0.8))
                    .frame(width: 34, height: 34)
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
            }
        }
    }
    
    // 初始化示例数据的标志
    @State private var hasInitializedData = false
    
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
        case .progress:
            return sortAscending ? 
                goals.sorted { $0.progress < $1.progress } : 
                goals.sorted { $0.progress > $1.progress }
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
    
    // 获取标签颜色
    private func tagColor(for tag: String) -> Color {
        return tagColorManager.getColor(for: tag)
    }
    
	
    
    var body: some View { 
        ZStack {
            // 主视图
            // 页面导航容器：Goal 页主 NavigationStack（目标列表的路由栈）
            NavigationStack(path: $navigationManager.goalNavigationPath) {
                ZStack(alignment: .top) {
                    // 悬浮的顶部标题栏（覆盖层），使用系统材质实现动态模糊
                    VStack(spacing: 0) {
                        // 第一行：标题和按钮
                        HStack(alignment: .center) {
                            // 侧边栏按钮
                            Button(action: {
                                SidebarManager.shared.showSidebar()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.systemGray5).opacity(0.8))
                                        .frame(width: 34, height: 34)
                                    
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(UIColor.label))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            HStack {
                                Text("目标/计划")
                                    .font(.system(size: 20, weight: .light, design: .rounded))
                                    .foregroundColor(Color(UIColor.label))
                                    .padding(.leading, 16)
                                
                                Spacer()
                            }
                            
                            Spacer()
                            
                            // 搜索按钮（仅在“全部”页签显示，点击弹出筛选弹窗）
                            if selectedGoalType == nil {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showGoalPopup = true
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(UIColor.systemGray5).opacity(0.8))
                                            .frame(width: 34, height: 34)
                                        
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // 年份选择器按钮（仅在年度目标时显示）
                            if selectedGoalType == .yearly {
                                Button(action: {
                                    dismissKeyboard()
                                    // 添加触觉反馈
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    withAnimation {
                                        showYearPicker.toggle()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text("\(currentYear)年")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(UIColor.label))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.9)
                                        
                                        Image(systemName: showYearPicker ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(Color(UIColor.label))
                                            .rotationEffect(.degrees(showYearPicker ? 0 : 0))
                                            .animation(.easeInOut(duration: 0.2), value: showYearPicker)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(UIColor.systemGray5).opacity(0.8))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(showYearPicker ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: showYearPicker)
                            }
                            
                            // 添加目标按钮
                            Button(action: {
                                showAddGoalSheet = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.systemGray5).opacity(0.8))
                                        .frame(width: 34, height: 34)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(UIColor.label))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 省略号菜单按钮，包含所有功能
                            ellipsisMenuContent
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        
                        // 导航标签：目标类型筛选页签（切换视图内容）
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
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .safeAreaPadding(.top)
                    .background(
                        BlurView(style: .systemMaterial)
                            .ignoresSafeArea(.all, edges: .top)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
                    .zIndex(10)
                    .overlay(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: HeaderHeightPreferenceKey.self, value: proxy.size.height)
                        }
                    )
                    .onPreferenceChange(HeaderHeightPreferenceKey.self) { height in
                        headerHeight = height
                    }
                    
                    // 顶栏已迁移为覆盖层，这里加入透明占位以避免初始内容被遮挡
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: headerHeight)
                    
                    // 输入框：目标搜索栏（控制关键词与筛选状态）
                    if showSearchBar {
                        searchBarView
                            .zIndex(9)
                    }
                
                // 年份选择器已移到顶栏下方的内容区域
                
                // 页面框：目标内容区域 TabView（按类型分页滑动）
                GeometryReader { geometry in
                    TabView(selection: $currentGoalTypeIndex) {
                        ForEach(goalTypes.indices, id: \.self) { index in
                            ScrollView {
                                VStack(spacing: 16) {
                                    // 移除了分类标题
                                    Spacer().frame(height: 8)
                                    // “全部”页签顶部筛选提示（页面上方，而非整个模块顶部）
                                    if goalTypes[index] == nil {
                                        let filtersActive = (popupSelectedGoalType != nil) || (selectedImportance != nil) || (!searchText.isEmpty) || (!selectedTags.isEmpty) || (selectedYear != nil)
                                        if filtersActive {
                                            HStack(spacing: 10) {
                                                Text("当前为筛选结果")
                                                    .font(.caption)
                                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color(UIColor.systemGray6))
                                                    .cornerRadius(15)

                                                Button(action: {
                                                    // 取消筛选：清空筛选条件与结果
                                                    popupSelectedGoalType = nil
                                                    selectedImportance = nil
                                                    searchText = ""
                                                    selectedTags.removeAll()
                                                    selectedYear = nil
                                                    savedFilteredGoals = []

                                                    // 同步移除持久化的筛选条件
                                                    let defaults = UserDefaults.standard
                                                    defaults.removeObject(forKey: "selectedGoalType")
                                                    defaults.removeObject(forKey: "selectedImportance")
                                                    defaults.removeObject(forKey: "goalSearchText")
                                                    defaults.removeObject(forKey: "goalFilterTags")
                                                    defaults.removeObject(forKey: "selectedYear")

                                                    updateFilteredGoals()
                                                }) {
                                                    Text("取消筛选")
                                                        .font(.caption)
                                                        .foregroundColor(Color(UIColor.systemBlue))
                                                        .underline()
                                                }

                                                Spacer()
                                            }
                                            .padding(.horizontal)
                                            .padding(.top, 8)
                                            // 当筛选结果为空时显示“无结果”提示
                                            if allTabDisplayGoals.isEmpty {
                                                HStack {
                                                    Text("无结果")
                                                        .font(.caption)
                                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                                    Spacer()
                                                }
                                                .padding(.horizontal)
                                            }
                                        }
                                }
                                
                                // 年度目标页签的年份选择器 - 与记录模块中年记的年份选择保持一致
                                if selectedSegment == 1 && showYearPicker && goalTypes[index] == .yearly {
                                    VStack(spacing: 8) {
                                        
                                        // 年份快速选择器 - 横向滚动列表形式
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                // 显示更多年份，提供连续的横向滚动体验
                                                ForEach(max(1, yearListBaseYear-10)...(yearListBaseYear+30), id: \.self) { year in
                                                    Button(action: {
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                            // 直接设置年份，不使用中间变量
                                                            currentYear = year
                                                            
                                                            // 调整基准年份，确保选中年份在可见范围中央位置
                                                            yearListBaseYear = max(1, year - 5)
                                                            
                                                            // 设置动画状态
                                                            yearChangeAnimation = true
                                                        }
                                                        
                                                        // 重置动画状态
                                                        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                                            yearChangeAnimation = false
                                                        }
                                                    }) {
                                                        ZStack {
                                                            if currentYear == year {
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .fill(Color.blue)
                                                                    .frame(width: 60, height: 36)
                                                            } else if Calendar.current.component(.year, from: Date()) == year && 
                                                                     Calendar.current.component(.year, from: Date()) != currentYear {
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .stroke(Color.blue, lineWidth: 2)
                                                                    .frame(width: 60, height: 36)
                                                            } else {
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .fill(Color(UIColor.systemGray6))
                                                                    .frame(width: 60, height: 36)
                                                                    .opacity(0.6)
                                                            }
                                                            Text("\(year)")
                                                                .monospacedDigit()
                                                                .font(.system(size: 16))
                                                                .fontWeight(currentYear == year ? .bold : .regular)
                                                                .foregroundColor(currentYear == year ? .white : .primary)
                                                                .frame(width: 60, height: 36)
                                                                .lineLimit(1)
                                                                .minimumScaleFactor(0.8)
                                                        }
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                        }
                                        .padding(.horizontal, -8) // 抵消父容器padding，实现边缘到边缘的滚动
                                    }
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.systemGroupedBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16) // 与目标条目之间间隔16px
                                }
                                
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
                                            AllGoalGalleryView(goals: sortGoals(allTabDisplayGoals), geometry: geometry)
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
                                            AllGoalListView(goals: sortGoals(allTabDisplayGoals))
                                        }
                                    }
                                }
                                .padding(.top, 110)
                                .padding(.bottom, 16)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentGoalTypeIndex) { _, newIndex in
                        // 同步更新selectedGoalType
                        selectedGoalType = goalTypes[newIndex]
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.bottom)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .tags:
                    TagsView()
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("我的标签")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    navigationManager.pop(for: selectedTab)
                                }
                            }
                        }
                case .settings:
                    SettingsView()
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("设置")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    navigationManager.pop(for: selectedTab)
                                }
                            }
                        }
                case .userEdit:
                    if let user = allUsers.first {
                        UserEditView(user: user)
                            .navigationBarBackButtonHidden(true)
                            .navigationTitle("我的信息")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("返回") {
                                        navigationManager.pop(for: selectedTab)
                                    }
                                }
                            }
                    } else {
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
            }
            
            // 移除年份变化提示
            .zIndex(1)
        }
        .sheet(isPresented: $showAddGoalSheet) {
                AddGoalView(isPresented: $showAddGoalSheet, selectedSegment: $selectedSegment)
            }
        .sheet(isPresented: $showTrashView) {
            TrashView()
        }
        // 筛选弹窗（仅“全部”页签入口触发）
        .sheet(isPresented: $showGoalPopup) {
            GoalPopupView(
                goalFilterExpanded: $goalFilterExpanded,
                selectedGoalType: $popupSelectedGoalType,
                selectedImportance: $selectedImportance,
                savedFilteredGoals: $savedFilteredGoals,
                searchText: $searchText,
                selectedTags: $selectedTags,
                selectedYear: $selectedYear
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadSavedGoalFilters()
            // 初始化年份列表基准年份，确保当前年份在中间位置
            yearListBaseYear = max(1, currentYear - 5)
        }
        .onChange(of: popupSelectedGoalType) { _, _ in
            updateFilteredGoals()
        }
        .onChange(of: selectedImportance) { _, _ in
            updateFilteredGoals()
        }
        .onChange(of: searchText) { _, newValue in
            isSearching = !newValue.isEmpty
            updateFilteredGoals()
        }
        .onChange(of: selectedTags) { _, _ in
            updateFilteredGoals()
        }
        // 移除模块级 overlay 提示，改为页签内顶部提示
        
        // 侧边栏移至应用根层，由全局 SidebarManager 控制
    }
    }
    
    // MARK: - Private Methods

    // 从 UserDefaults 加载并应用筛选条件
    private func loadSavedGoalFilters() {
        let defaults = UserDefaults.standard
        goalFilterExpanded = defaults.bool(forKey: "goalFilterExpanded")

        if let typeRaw = defaults.string(forKey: "selectedGoalType"), let type = GoalType(rawValue: typeRaw) {
            popupSelectedGoalType = type
        } else {
            popupSelectedGoalType = nil
        }

        if let importanceObj = defaults.object(forKey: "selectedImportance") as? Int, let imp = GoalImportance(rawValue: importanceObj) {
            selectedImportance = imp
        } else {
            selectedImportance = nil
        }

        searchText = defaults.string(forKey: "goalSearchText") ?? ""
        if let tagArray = defaults.array(forKey: "goalFilterTags") as? [String] {
            selectedTags = Set(tagArray)
        } else {
            selectedTags = []
        }
        
        // 加载年份筛选
        if let year = defaults.object(forKey: "selectedYear") as? Int {
            selectedYear = year
        } else {
            selectedYear = nil
        }
        
        updateFilteredGoals()
    }

    // 根据当前筛选条件更新筛选结果数组
    private func updateFilteredGoals() {
        let goalsSource = allGoals
        let filtered = goalsSource.filter { goal in
            // 检查类型匹配
            let typeMatches = (popupSelectedGoalType == nil) || (goal.goalType == popupSelectedGoalType)
            if !typeMatches {
                return false
            }
            
            // 检查重要性匹配
            let importanceMatches = (selectedImportance == nil) || (goal.goalImportance == selectedImportance)
            if !importanceMatches {
                return false
            }
            
            // 检查标签匹配
            let tagMatches = selectedTags.isEmpty || goal.tags.contains { tag in
                return selectedTags.contains(tag)
            }
            if !tagMatches {
                return false
            }
            
            // 检查年份匹配
            var yearMatches = true
            if selectedYear != nil {
                yearMatches = false
                if let dueDate = goal.dueDate {
                    let dueDateYear = Calendar.current.component(.year, from: dueDate)
                    if dueDateYear == selectedYear {
                        yearMatches = true
                    }
                }
            }
            if !yearMatches {
                return false
            }
            
            // 检查搜索文本匹配
            let nameMatches = searchText.isEmpty || goal.name.localizedCaseInsensitiveContains(searchText)
            let descriptionMatches = searchText.isEmpty || goal.goalDescription.localizedCaseInsensitiveContains(searchText)
            
            var tagSearchMatches = false
            if searchText.isEmpty {
                tagSearchMatches = true
            } else {
                for tag in goal.tags {
                    if tag.localizedCaseInsensitiveContains(searchText) {
                        tagSearchMatches = true
                        break
                    }
                }
            }
            
            let searchMatches = nameMatches || descriptionMatches || tagSearchMatches
            return searchMatches
        }
        savedFilteredGoals = filtered
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
    
    // 搜索栏视图
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            // 输入框：搜索关键词（Goal页搜索主入口）
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
            return sortGoals(allTabDisplayGoals)
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
    var cardWidth: CGFloat?
    var isFixedHeightContainer: Bool = false
    @State private var nameAndDescHeight: CGFloat = 0
    private let minCardHeight: CGFloat = 60
    private let horizontalPadding: CGFloat = 6 // 卡片内边距与进度/标签水平内边距
    private let elementSpacing: CGFloat = 10     // 元素间距建议值
    
    // 初始化方法，提供默认值
    init(goal: Goal, cardWidth: CGFloat? = nil, isFixedHeightContainer: Bool = false) {
        self.goal = goal
        self.cardWidth = cardWidth
        self.isFixedHeightContainer = isFixedHeightContainer
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

    // 文本高度计算（考虑换行与最大行数），用于自适应卡片高度
    private func textHeight(_ text: String, font: UIFont, width: CGFloat, maxLines: Int) -> CGFloat {
        guard !text.isEmpty, width > 0 else { return 0 }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]
        let bounding = (text as NSString).boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        // 每行近似高度
        let lineHeight = font.lineHeight
        // 限制最大行数
        let maxHeight = lineHeight * CGFloat(max(1, maxLines))
        return min(ceil(bounding.height), ceil(maxHeight))
    }

    // 根据可见元素动态计算卡片高度
    private func calculatedCardHeight(for width: CGFloat) -> CGFloat {
        let contentWidth = max(0, width - horizontalPadding * 1.6) // 估算可用文本宽度，考虑圆点与内边距

        // 顶部：名称（2行）+ 可选描述（3行）
        let nameFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let descFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let nameHeight = textHeight(goal.name, font: nameFont, width: contentWidth, maxLines: 2)
        let descHeight = textHeight(goal.goalDescription, font: descFont, width: contentWidth, maxLines: 3)
        let topVStackSpacing: CGFloat = 4
        let topAreaHeight = nameHeight + (descHeight > 0 ? (topVStackSpacing + descHeight) : 0)

        var total: CGFloat = 0
        let topPadding: CGFloat = 16
        total += topPadding
        // 顶部区域至少占据名称高度
        total += max(24, topAreaHeight)
        // 与进度条的间距
        total += elementSpacing - 2 // 当前布局中顶部到进度条为6
        // 进度条高度与自身上边距
        total += 6 /* bar height */ + 6 /* top padding */

        // 标签区域（存在则计入）
        if !goal.tags.isEmpty {
            total += elementSpacing
            total += 24 /* 标签行固定高度 */
        }

        // 子任务区域（存在则计入）
        if !goal.tasks.isEmpty {
            total += elementSpacing
            // 列表高度（最多2条）；1条为24，2条为52
            total += goal.tasks.count == 1 ? 24 : 52
            // 内部上下间距及外部额外底部留白
            total += 6 /* top padding */ + 20 /* bottom padding */ + 20 /* outer bottom padding */
        }

        // 底部额外留白，避免内容贴边
        total += 16

        // 安全最小高度，避免0或负值
        return max(minCardHeight, ceil(total))
    }
    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            ZStack(alignment: .topLeading) {
                // 背景图片或默认渐变背景 - 置于底层
                if let imageName = goal.backgroundImage {
                    // 首先尝试从应用资源中加载预设图片
                    if let uiImage = UIImage(named: imageName) {
                        // 预设背景图片 - 占满整个卡片
                        let width = cardWidth ?? 160
                        let height = calculatedCardHeight(for: width)
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height, alignment: .topLeading)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .opacity(0.7)
                    } else {
                        // 尝试从文档目录加载用户自定义图片
                        let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
                        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                            // 用户自定义背景图片 - 占满整个卡片
                            let width = cardWidth ?? 160
                            let height = calculatedCardHeight(for: width)
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: height, alignment: .topLeading)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .opacity(0.7)
                                .blur(radius: 1.5)
                        }
                    }
                } else {
                    // 默认渐变背景 - 占满整个卡片
                    let width = cardWidth ?? 160
                    let height = calculatedCardHeight(for: width)
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: width, height: height, alignment: .topLeading)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // 添加半透明覆盖层，使内容更易读
                do {
                    let width = cardWidth ?? 160
                    let height = calculatedCardHeight(for: width)
                    Rectangle()
                        .fill(Color(UIColor.systemBackground).opacity(0.5))
                        .frame(width: width, height: height, alignment: .topLeading)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // 卡片阴影
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .shadow(color: Color(UIColor.label).opacity(0.15), radius: 8, x: 0, y: 4)
                
                // 内容容器 - 所有元素放在同一图层，向左上角对齐
                VStack(alignment: .leading, spacing: elementSpacing) {
                    Spacer().frame(height: 0)
                    
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
                    .padding(.horizontal, horizontalPadding)
                    
                    // 标签区域
                    if !goal.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(goal.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(TagColorManager.shared.getColor(for: tag))
                                        .foregroundColor(.white)
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
                        .padding(.horizontal, horizontalPadding)
                        .frame(height: 24)
                    }
                    
                    // 子任务区域
                    if !goal.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
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
                                                if task.isCompleted {
                                                    // 已完成的任务显示灰色背景和白色勾选标记
                                                    Circle()
                                                        .fill(Color(UIColor.systemGray4))
                                                        .frame(width: 18, height: 18)
                                                    
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(.white)
                                                } else {
                                                    // 未完成的任务显示外圈
                                                    Circle()
                                                        .stroke(Color(UIColor.systemGray3), lineWidth: 1.5)
                                                        .frame(width: 18, height: 18)
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
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 20)
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.7))
                        .cornerRadius(12)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 20)
                    }
                    // 添加底部空白，推动内容向上
                    Spacer()
                }
                .padding(16) // 统一卡片内容内边距为16px
                .frame(maxWidth: cardWidth, alignment: .topLeading) // 确保内容容器占满整个卡片宽度并向左上角对齐
            }
            // 应用动态高度以确保背景图在超出时按左上角裁剪
            .frame(width: cardWidth, height: calculatedCardHeight(for: cardWidth ?? 160), alignment: .topLeading)
            .clipped() // 保证背景与内容不越界，避免与其他卡片重叠
            .clipShape(RoundedRectangle(cornerRadius: 20)) // 统一圆角外观，确保与其他卡片一致
            // 移除右上角“目标”标签
        }
        .buttonStyle(PlainButtonStyle()) // 移除导航链接的默认样式
    }
}

// 列表视图中的目标项
struct GoalListItem: View {
    let goal: Goal
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
    // 获取标签颜色的函数
    private func tagColor(for tag: String) -> Color {
        return tagColorManager.getColor(for: tag)
    }
    
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
                                        .background(tagColor(for: tag))
                                        .foregroundColor(.white)
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
            // 页面导航容器：添加目标表单的导航栈（顶部标题与按钮）
            NavigationView {
                // 页面框：添加目标的表单主体（包含各类输入控件）
                Form {
                    Section(header: Text("目标信息")) {
                        // 输入框：目标名称（必填）
                        TextField("目标名称", text: $goalName)
                            .overlay(
                                goalName.isEmpty ? 
                                Text("目标名称不能为空").foregroundColor(.red).font(.caption) : nil,
                                alignment: .trailing
                            )
                        
                        // 输入框：目标描述（可选，支持长文本）
                        TextField("目标描述", text: $goalDescription)
                            .frame(height: 80)
                        
                        // 选择控件：目标类别（影响展示与分类）
                        Picker("类别", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        
                        // 输入框：标签（逗号分隔，用于筛选与标注）
                        TextField("标签 (用逗号分隔)", text: $tags)
                        
                        // 开关控件：是否设置截止日期
                        Toggle("设置截止日期", isOn: $hasDueDate)
                        
                        if hasDueDate {
                            // 日期选择器：目标截止日期
                            DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date])
                        }
                    }
                }
                .navigationBarTitle("添加目标", displayMode: .inline)
                // 顶栏：添加目标页的取消/保存按钮（右侧保存，左侧取消）
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
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
    // 获取标签颜色的函数
    private func tagColor(for tag: String) -> Color {
        return tagColorManager.getColor(for: tag)
    }
    
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

// MARK: - 键盘隐藏函数
private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
