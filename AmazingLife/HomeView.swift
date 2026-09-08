//
//  HomeView.swift
//  selfManager
//
//  Created by Zack on 2024/12/31.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - 轻微晃动效果（文件作用域）
struct JiggleEffect: ViewModifier {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var rotation: Double = -1.2
    @State private var sway: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive ? rotation : 0))
            .offset(x: isActive ? sway : 0)
            .onAppear {
                if reduceMotion { return }
                if isActive {
                    withAnimation(Animation.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) {
                        rotation = 1.2
                        sway = 0.8
                    }
                }
            }
            .onChange(of: isActive) { active in
                if reduceMotion {
                    rotation = 0
                    sway = 0
                    return
                }
                if active {
                    rotation = -1.2
                    sway = -0.8
                    withAnimation(Animation.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) {
                        rotation = 1.2
                        sway = 0.8
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.12)) {
                        rotation = 0
                        sway = 0
                    }
                }
            }
    }
}

extension View {
    func jiggle(_ isActive: Bool) -> some View {
        modifier(JiggleEffect(isActive: isActive))
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Query(sort: \Goal.createTime, order: .reverse) private var goals: [Goal]
    @Query(sort: \Record.createTime, order: .reverse) private var records: [Record]
    
    // 卡片显示控制
    @AppStorage("showAssetCard") private var showAssetCard = true
    @AppStorage("showHabitCard") private var showHabitCard = true
    @AppStorage("showAchievementCard") private var showAchievementCard = true
    @AppStorage("showAnxietyCard") private var showAnxietyCard = true
    @AppStorage("showPinnedSubtasksCard") private var showPinnedSubtasksCard = true
    
    // 观察TagColorManager的变化以实现即时更新
    @ObservedObject private var tagColorManager = TagColorManager.shared
    // 被Ping目标管理器
    @ObservedObject private var pingManager = PingManager.shared
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var showingEdit = false
    @State private var showingAssetDetail = false
    @State private var showingImprovementDetail = false
    @State private var showingAchievementDetail = false

    // MARK: - 可排序的主页卡片类型与拖拽状态
    enum HomeCardType: String, Codable, CaseIterable, Hashable {
        case profile
        case asset
        case habit     // 习惯卡片
        case pingedGoals // 旧分组卡片（不再使用）
        case goals
        case mood      // 心情卡片（独立模块）
        case achievement // 成就卡片（独立模块）
        case pinnedSubtasks // 置顶子任务卡片（独立模块）
        case improvement
    }

    enum HomeCardID: Hashable, Codable {
        case type(HomeCardType)
        case pingedGoal(UUID)
        case pingedContact(UUID)
    }

    // 卡片尺寸枚举与状态
    enum HomeCardSize: String, Codable, CaseIterable {
        case small   // 1行 × 1列
        case medium  // 1行 × 2列
        case large   // 2行 × 2列
    }

    @State private var cardSizesByID: [HomeCardID: HomeCardSize] = [:]
    private let smallRowHeight: CGFloat = 160
    private let gridSpacing: CGFloat = 16
    private var largeRowHeight: CGFloat { smallRowHeight * 2 + gridSpacing }

    @State private var cardOrderIDs: [HomeCardID] = []
    @State private var draggingCardID: HomeCardID? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardFramesByID: [HomeCardID: CGRect] = [:]
    @State private var cardOffsetsByID: [HomeCardID: CGSize] = [:]
    // 移动模式与菜单状态
    @State private var moveModeEnabledForID: HomeCardID? = nil
    @State private var expandedCardsByID: Set<HomeCardID> = []
    // 最近一次交换时的拖拽位移基线，避免重复计算导致跳动
    @State private var lastSwapTranslationY: CGFloat = 0

    private struct CardFramePreferenceKey: PreferenceKey {
        static var defaultValue: [HomeCardID: CGRect] = [:]
        static func reduce(value: inout [HomeCardID: CGRect], nextValue: () -> [HomeCardID: CGRect]) {
            value.merge(nextValue()) { _, new in new }
        }
    }

    
    // 侧边栏状态管理
    @ObservedObject private var sidebarManager = SidebarManager.shared
    
    // 用户信息
    @Query private var users: [User]
    
    // 联系人信息
    @Query private var contacts: [Contact]
    
    private var user: User {
        if let firstUser = users.first {
            return firstUser
        } else {
            let newUser = User()
            modelContext.insert(newUser)
            return newUser
        }
    }
    
    // 资产信息
    @Query(sort: \Asset.lastUpdateDate, order: .reverse) private var assets: [Asset]
    
    private var asset: Asset {
        if let firstAsset = assets.first {
            return firstAsset
        } else {
            let newAsset = Asset()
            modelContext.insert(newAsset)
            return newAsset
        }
    }
    
    // 心情数据
    private let moods = ["😊", "😢", "😡", "😴", "🤔", "😎"]

    // 最近三篇日记的心情（如果存在）
    private var latestDailyMoods: [String] {
        let moods = records
            .filter { $0.recordType == .daily && $0.mood != nil }
            .prefix(3)
            .compactMap { $0.mood }
        return Array(moods)
    }
    
    // 成就数据
    @Query(sort: \Achievement.completionDate, order: .reverse) private var achievements: [Achievement]
    
    // 弱点数据
    private let weakPoints = ["🍔", "🛌", "📱"]
    
    // 待改进数据
    private let improvements = ["📱", "🍔", "🛌", "🎮", "💤"]
    
    // 待改进标签
    private let improvementLabels = ["手机使用", "饮食习惯", "作息时间", "游戏时间", "午休习惯"]
    
    // 焦虑数据
    private let anxieties = ["工作压力大", "睡眠不足", "缺乏锻炼"]

    // 根据标签筛选的目标集合
    private var achievementGoals: [Goal] {
        goals.filter { !$0.isDeleted && $0.tags.contains(BuiltInTags.achievement) }
    }
    private var anxietyGoals: [Goal] {
        goals.filter { !$0.isDeleted && $0.tags.contains(BuiltInTags.anxiety) }
    }

    // 置顶子任务集合
    private var pinnedTaskIDs: [UUID] {
        let arr = UserDefaults.standard.stringArray(forKey: "PinnedSubtaskIDs") ?? []
        return arr.compactMap { UUID(uuidString: $0) }
    }
    private var pinnedSubtasks: [GoalTask] {
        var result: [GoalTask] = []
        for g in goals {
            for t in g.tasks {
                if pinnedTaskIDs.contains(t.id) { result.append(t) }
            }
        }
        return result
    }
    private func unpin(task: GoalTask) {
        var arr = UserDefaults.standard.stringArray(forKey: "PinnedSubtaskIDs") ?? []
        if let idx = arr.firstIndex(of: task.id.uuidString) {
            arr.remove(at: idx)
            UserDefaults.standard.set(arr, forKey: "PinnedSubtaskIDs")
        }
    }

    // 最近焦虑统计（基于创建时间）
    private var recentAnxietyWeeklyCount: Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        return anxietyGoals.filter { $0.createTime >= start }.count
    }

    private var recentAnxietyMonthlyCount: Int {
        let cal = Calendar.current
        let now = Date()
        guard let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        return anxietyGoals.filter { $0.createTime >= startOfMonth }.count
    }

    private var last7DaysAnxietyCounts: [Int] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
            return anxietyGoals.filter { g in cal.isDate(g.createTime, inSameDayAs: day) }.count
        }.reversed()
    }
    
    // 初始化方法
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    // 获取所有标签
    private func getAllTags() -> [String] {
        var tags = Set<String>()
        
        // 收集目标标签
        for goal in goals where !goal.isDeleted {
            for tag in goal.tags {
                tags.insert(tag)
            }
        }
        
        // 收集联系人标签
        for contact in contacts {
            for tag in contact.tags {
                tags.insert(tag)
            }
        }
        
        // 收集用户标签
        for user in users {
            for tag in user.tags {
                tags.insert(tag)
            }
        }
        
        return Array(tags).sorted()
    }
    
    var body: some View {
        // 页面导航容器：Home 页的主 NavigationStack（路由和返回栈）
                NavigationStack(path: $navigationManager.homeNavigationPath) {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部间距
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40) // 将高度从 140 减小到 80
                        
                        // 主页卡片渲染（支持长按拖拽排序）
                        MasonryLayout(spacing: 16, minColumnWidth: 320) {
                            ForEach(cardOrderIDs, id: \.self) { id in
                                renderCard(for: id)
                                    .masonrySpan(spanForCard(id))
                            }
                        }
                        .animation(.interactiveSpring(), value: cardOrderIDs)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                    .onPreferenceChange(CardFramePreferenceKey.self) { frames in
                        // 为实现拖拽过程中动态让位，需要在拖拽时也更新快照
                        // 使用DispatchQueue.main.async避免在同一帧内多次更新
                        DispatchQueue.main.async {
                            if shouldUpdateCardFrames(frames, comparedTo: cardFramesByID) {
                                cardFramesByID = frames
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .coordinateSpace(name: "scroll")
                
                // 悬浮的顶部标题栏
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        // 侧边栏按钮 - 只在主页显示
                        Button(action: {
                            sidebarManager.toggleSidebar()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemGray5).opacity(0.8))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(UIColor.label))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("me".localized)
                            .font(AppFont.navTitle())
                            .foregroundColor(Color(UIColor.label))
                            .padding(.leading, 12)
                        
                        Spacer()
                        
                        // 通知按钮
                        Button(action: {}) {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.1))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: "bell")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, 44) // 使用固定值代替弃用的API
                }
                .frame(maxWidth: .infinity)
                .background(BlurView(style: .systemMaterial))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
                .ignoresSafeArea(.all, edges: .top)
            }
            .navigationBarHidden(true)
            // 通过路由类型进行页面 push 映射
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .tags:
                    TagsView()
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("my_tags".localized)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    navigationManager.pop(for: selectedTab)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                        Text("back".localized)
                                    }
                                }
                            }
                        }
                case .settings:
                    SettingsView()
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("设置")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    navigationManager.pop(for: selectedTab)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("返回")
                                            .font(.system(size: 17, weight: .medium))
                                    }
                                    .foregroundColor(Color(UIColor.systemBlue))
                                }
                            }
                        }
                case .assets:
                    AssetDetailView()
                case .profile:
                    if let firstUser = users.first {
                        UserEditView(user: firstUser)
                    } else {
                        Text("暂无用户信息")
                    }
                case .userEdit:
                    if let firstUser = users.first {
                        UserEditView(user: firstUser)
                    } else {
                        Text("暂无用户信息")
                    }
                case .achievements:
                    TagDetailView(tag: BuiltInTags.achievement, tagType: .goal)
                case .anxieties:
                    TagDetailView(tag: BuiltInTags.anxiety, tagType: .goal)
                case .tagDetail(let tagName):
                    TagDetailView(tag: tagName, tagType: .all)
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("标签详情")
                case .contactTrash:
                    EmptyView() // HomeView不处理contactTrash路由，这个路由只在ContactView中处理
                }
            }
        }

        .onAppear {
            // 在视图加载时应用保存的筛选条件，但避免重复加载

            if savedFilteredGoals.isEmpty {
                loadSavedGoalFilters()
            }
            // 加载主页卡片排序（按 ID 渲染，包括独立的 Ping 目标）
            loadCardOrderIDs()
            // 加载并应用卡片尺寸设置
            loadCardSizes()
        }
        .onChange(of: selectedGoalType) {
            updateFilteredGoals()
        }
        .onChange(of: selectedImportance) {
            updateFilteredGoals()
        }
        .onChange(of: searchText) {
            updateFilteredGoals()
        }
        .onChange(of: pingManager.allPingedGoalIDs) {
            syncPingedGoalCardsIntoOrder()
        }
        .onChange(of: pingManager.allPingedContactIDs) {
            syncPingedContactCardsIntoOrder()
        }
    }



// 计算使用特定标签的项目数量
private func countItemsWithTag(_ tag: String) -> Int {
    var count = 0
    
    // 计算带有此标签的目标数量
    count += goals.filter { $0.tags.contains(tag) }.count
    
    // 计算带有此标签的联系人数量
    count += contacts.filter { $0.tags.contains(tag) }.count
    
    // 计算带有此标签的用户数量
    count += users.filter { $0.tags.contains(tag) }.count
    
    return count
}

// MARK: - ID 排序持久化与同步
private let cardOrderIDsKey = "home.card.order.ids.v1"

private func defaultCardOrderIDs() -> [HomeCardID] {
    var ids: [HomeCardID] = [
        .type(.profile),
        .type(.asset)
    ]
    // 将现有被Ping目标作为独立卡片插入
    for gid in pingManager.allPingedGoalIDs {
        ids.append(.pingedGoal(gid))
    }
    // 将现有被Ping联系人作为独立卡片插入
    for cid in pingManager.allPingedContactIDs {
        ids.append(.pingedContact(cid))
    }
    // 追加其他静态卡片（不包含旧的 .pingedGoals 分组卡片）
    ids.append(contentsOf: [
        .type(.habit),
        .type(.pinnedSubtasks),
        .type(.achievement),
        .type(.improvement)
    ])
    return ids
}

private func encodeHomeCardID(_ id: HomeCardID) -> String {
    switch id {
    case .type(let t):
        return "T:" + t.rawValue
    case .pingedGoal(let gid):
        return "G:" + gid.uuidString
    case .pingedContact(let cid):
        return "C:" + cid.uuidString
    }
}

private func decodeHomeCardID(_ s: String) -> HomeCardID? {
    if s.hasPrefix("T:") {
        let raw = String(s.dropFirst(2))
        if let t = HomeCardType(rawValue: raw) {
            // 过滤掉旧的分组卡片
            if t == .pingedGoals { return nil }
            return .type(t)
        }
        // 兼容旧版本：如果读到 moodAchievement，迁移为两个独立模块
        if raw == "moodAchievement" {
            // 返回 nil，让 loadCardOrderIDs 在必备静态卡片阶段补全 mood 与 achievement
            return nil
        }
        return nil
    } else if s.hasPrefix("G:") {
        let raw = String(s.dropFirst(2))
        if let uuid = UUID(uuidString: raw) {
            return .pingedGoal(uuid)
        }
        return nil
    } else if s.hasPrefix("C:") {
        let raw = String(s.dropFirst(2))
        if let uuid = UUID(uuidString: raw) {
            return .pingedContact(uuid)
        }
        return nil
    }
    return nil
}

private func loadCardOrderIDs() {
    if let raw = UserDefaults.standard.array(forKey: cardOrderIDsKey) as? [String] {
        var decoded = raw.compactMap { decodeHomeCardID($0) }
        if !decoded.isEmpty {
            // 移除已被取消Ping的目标卡片
            decoded.removeAll { id in
                if case .pingedGoal(let gid) = id {
                    return !pingManager.allPingedGoalIDs.contains(gid)
                }
                return false
            }
            // 移除已被取消Ping的联系人卡片
            decoded.removeAll { id in
                if case .pingedContact(let cid) = id {
                    return !pingManager.allPingedContactIDs.contains(cid)
                }
                return false
            }
            // 移除旧的合并卡片（如果存在于历史编码中）
            decoded.removeAll { id in
                if case .type(let t) = id, t.rawValue == "moodAchievement" { return true }
                return false
            }
            // 移除心情卡片（删除该模块后清理历史顺序项）
            decoded.removeAll { id in
                if case .type(let t) = id, t == .mood { return true }
                return false
            }
            // 确保静态卡片存在
            let requiredStatics: [HomeCardType] = [.profile, .asset, .habit, .pinnedSubtasks, .achievement, .improvement]
            for t in requiredStatics {
                let tid = HomeCardID.type(t)
                if !decoded.contains(tid) {
                    decoded.insert(tid, at: max(0, min(decoded.count, 0)))
                }
            }
            // 添加新的被Ping目标卡片（默认追加到末尾）
            for gid in pingManager.allPingedGoalIDs {
                let pid = HomeCardID.pingedGoal(gid)
                if !decoded.contains(pid) { decoded.append(pid) }
            }
            // 添加新的被Ping联系人卡片（默认追加到末尾）
            for cid in pingManager.allPingedContactIDs {
                let pid = HomeCardID.pingedContact(cid)
                if !decoded.contains(pid) { decoded.append(pid) }
            }
            cardOrderIDs = decoded
            return
        }
    }
    cardOrderIDs = defaultCardOrderIDs()
}

private func saveCardOrderIDs() {
    let encoded = cardOrderIDs.map { encodeHomeCardID($0) }
    UserDefaults.standard.set(encoded, forKey: cardOrderIDsKey)
}

private func syncPingedGoalCardsIntoOrder() {
    var current = cardOrderIDs
    // 移除不再被Ping的目标卡片
    current.removeAll { id in
        if case .pingedGoal(let gid) = id {
            return !pingManager.allPingedGoalIDs.contains(gid)
        }
        return false
    }
    // 添加新的被Ping的目标卡片（追加到末尾）
    for gid in pingManager.allPingedGoalIDs {
        let pid = HomeCardID.pingedGoal(gid)
        if !current.contains(pid) { current.append(pid) }
    }
    // 不引入旧的分组卡片
    current.removeAll { id in
        if case .type(let t) = id, t == .pingedGoals { return true }
        return false
    }
    cardOrderIDs = current
    saveCardOrderIDs()
}

private func syncPingedContactCardsIntoOrder() {
    var current = cardOrderIDs
    // 移除不再被Ping的联系人卡片
    current.removeAll { id in
        if case .pingedContact(let cid) = id {
            return !pingManager.allPingedContactIDs.contains(cid)
        }
        return false
    }
    // 添加新的被Ping的联系人卡片（追加到末尾）
    for cid in pingManager.allPingedContactIDs {
        let pid = HomeCardID.pingedContact(cid)
        if !current.contains(pid) { current.append(pid) }
    }
    // 不引入旧的分组卡片
    current.removeAll { id in
        if case .type(let t) = id, t == .pingedGoals { return true }
        return false
    }
    cardOrderIDs = current
    saveCardOrderIDs()
}

// MARK: - 卡片尺寸持久化与计算
private let cardSizesKey = "home.card.sizes.v1"

private func defaultSizeForID(_ id: HomeCardID) -> HomeCardSize {
    switch id {
    case .type(let t):
        switch t {
        case .profile, .asset:
            return .medium
        case .pinnedSubtasks:
            return .medium
        default:
            return .small
        }
    case .pingedGoal, .pingedContact:
        return .small
    }
}

private func loadCardSizes() {
    if let raw = UserDefaults.standard.dictionary(forKey: cardSizesKey) as? [String: String] {
        var result: [HomeCardID: HomeCardSize] = [:]
        for (encodedID, rawSize) in raw {
            if let id = decodeHomeCardID(encodedID), let size = HomeCardSize(rawValue: rawSize) {
                result[id] = size
            }
        }
        cardSizesByID = result
    } else {
        cardSizesByID = [:]
    }
}

private func saveCardSizes() {
    var raw: [String: String] = [:]
    for (id, size) in cardSizesByID {
        raw[encodeHomeCardID(id)] = size.rawValue
    }
    UserDefaults.standard.set(raw, forKey: cardSizesKey)
}

private func setCardSize(_ size: HomeCardSize, for id: HomeCardID) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
        cardSizesByID[id] = size
    }
    saveCardSizes()
}

private func widthSpanForCard(_ id: HomeCardID) -> Int {
    let size = cardSizesByID[id] ?? defaultSizeForID(id)
    switch size {
    case .small: return 1
    case .medium: return 2
    case .large: return 2
    }
}

private func heightForCard(_ id: HomeCardID) -> CGFloat {
    let size = cardSizesByID[id] ?? defaultSizeForID(id)
    switch size {
    case .small, .medium:
        return smallRowHeight
    case .large:
        return largeRowHeight
    }
}

// MARK: - 拖拽排序：渲染卡片及交互逻辑
@ViewBuilder
private func renderCard(_ type: HomeCardType) -> some View {
    let id = HomeCardID.type(type)
    let isDragging = (draggingCardID == id)
    switch type {
    case .profile:
        withMoveGesture(
            userProfileSection
                .frame(height: heightForCard(id))
                .background(cardFrameReader(for: type))
                .offset(isDragging ? dragOffset : .zero)
                .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                .scaleEffect(isDragging ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                .zIndex(isDragging ? 20 : 0)
                .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                .contentShape(Rectangle())
                .contextMenu { cardContextMenu(for: type) }
            , for: type)
            .sheet(isPresented: $showingEdit) {
                UserEditView(user: user)
            }
    case .asset:
        if showAssetCard {
            withMoveGesture(
                assetSection
                    .frame(height: heightForCard(id))
                    .background(cardFrameReader(for: type))
                    .offset(isDragging ? dragOffset : .zero)
                    .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                    .scaleEffect(isDragging ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                    .zIndex(isDragging ? 20 : 0)
                    .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                    .contentShape(Rectangle())
                    .contextMenu { cardContextMenu(for: type) }
                , for: type)
        } else {
            EmptyView()
        }
    case .habit:
        if showHabitCard {
            withMoveGesture(
                HabitCardView(cardSizesByID: cardSizesByID, defaultSizeForID: defaultSizeForID)
                    .frame(height: heightForCard(id))
                    .background(cardFrameReader(for: type))
                    .offset(isDragging ? dragOffset : .zero)
                    .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                    .scaleEffect(isDragging ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                    .zIndex(isDragging ? 20 : 0)
                    .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                    .contentShape(Rectangle())
                    .contextMenu { cardContextMenu(for: type) }
                , for: type)
        } else {
            EmptyView()
        }
    case .pingedGoals:
        // 旧的“被Ping目标分组卡片”不再使用，避免重复渲染
        EmptyView()
    case .goals:
        // 隐藏“近期目标”卡片
        EmptyView()
    case .mood:
        // 心情卡片已删除，保持占位为空视图以兼容历史枚举
        EmptyView()
    case .achievement:
        if showAchievementCard {
            withMoveGesture(
                achievementSection
                    .frame(height: heightForCard(id))
                    .background(cardFrameReader(for: type))
                    .offset(isDragging ? dragOffset : .zero)
                    .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                    .scaleEffect(isDragging ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                    .zIndex(isDragging ? 20 : 0)
                    .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                    .contentShape(Rectangle())
                    .contextMenu { cardContextMenu(for: type) }
            , for: type)
        } else {
            EmptyView()
        }
    case .pinnedSubtasks:
        if showPinnedSubtasksCard {
            withMoveGesture(
                pinnedSubtasksSection
                    .frame(height: heightForCard(id))
                    .background(cardFrameReader(for: type))
                    .offset(isDragging ? dragOffset : .zero)
                    .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                    .scaleEffect(isDragging ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                    .zIndex(isDragging ? 20 : 0)
                    .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                    .contentShape(Rectangle())
                    .contextMenu { cardContextMenu(for: type) }
            , for: type)
        } else {
            EmptyView()
        }
    case .improvement:
        if showAnxietyCard {
            withMoveGesture(
                improvementSection
                    .frame(height: heightForCard(id))
                    .background(cardFrameReader(for: type))
                    .offset(isDragging ? dragOffset : .zero)
                    .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                    .scaleEffect(isDragging ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                    .zIndex(isDragging ? 20 : 0)
                    .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                    .contentShape(Rectangle())
                    .contextMenu { cardContextMenu(for: type) }
                , for: type)
        } else {
            EmptyView()
        }
    default:
        EmptyView()
    }
}

@ViewBuilder
private func renderCard(for id: HomeCardID) -> some View {
    switch id {
    case .type(let type):
        renderCard(type)
    case .pingedGoal(let gid):
        if let goal = goals.first(where: { $0.id == gid }) {
            withMoveGesture(
                HomeGoalCard(goal: goal, isFixedHeightContainer: true)
                    // 提供给 Masonry 固定高度，避免 sizeThatFits 高度失控
                    .layoutValue(key: MasonryHeightKey.self, value: heightForCard(id))
                    .frame(height: heightForCard(id), alignment: .top) // 当内容超出时优先显示顶部
                    .clipped() // 防止内部内容越界导致与其他卡片重叠
                    .clipShape(RoundedRectangle(cornerRadius: 20)) // 与其它卡片保持一致的圆角外观
                    .background(cardFrameReader(for: id))
                    .offset({
                        let base = cardOffsetsByID[id] ?? .zero
                        let extra = (draggingCardID == id) ? dragOffset : .zero
                        return CGSize(width: base.width + extra.width, height: base.height + extra.height)
                    }())
                    .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                    .scaleEffect(draggingCardID == id ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                    .zIndex(draggingCardID == id ? 20 : 0)
                    .shadow(color: Color(UIColor.label).opacity(draggingCardID == id ? 0.12 : 0.06), radius: draggingCardID == id ? 10 : 8, x: 0, y: draggingCardID == id ? 6 : 4)
                    .contentShape(Rectangle())
                , for: id)
        } else {
            Color.clear.frame(height: 20)
        }
    case .pingedContact(let cid):
                if let contact = contacts.first(where: { $0.id == cid }) {
                    let size = cardSizesByID[id] ?? defaultSizeForID(id)
                    withMoveGesture(
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            HomeContactCard(contact: contact, size: size, containerHeight: heightForCard(id))
                                .layoutValue(key: MasonryHeightKey.self, value: heightForCard(id))
                                .frame(height: heightForCard(id), alignment: .top)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                // 右上角类型角标：人脉（保持当前样式不变）
                                .overlay(alignment: .topTrailing) {
                                    Text("人脉")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
                                        )
                                        .padding(8)
                                }
                                .background(cardFrameReader(for: id))
                            .offset({
                                    let base = cardOffsetsByID[id] ?? .zero
                                    let extra = (draggingCardID == id) ? dragOffset : .zero
                                    return CGSize(width: base.width + extra.width, height: base.height + extra.height)
                                }())
                                .jiggle(moveModeEnabledForID == id && draggingCardID == nil)
                                .scaleEffect(draggingCardID == id ? 1.02 : (expandedCardsByID.contains(id) ? 1.04 : 1.0))
                                .zIndex(draggingCardID == id ? 20 : 0)
                                .shadow(color: Color(UIColor.label).opacity(draggingCardID == id ? 0.12 : 0.06), radius: draggingCardID == id ? 10 : 8, x: 0, y: draggingCardID == id ? 6 : 4)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        , for: id)
                } else {
                    Color.clear.frame(height: 20)
                }
            }
}

private func cardFrameReader(for id: HomeCardID) -> some View {
    GeometryReader { geo in
        Color.clear
            .preference(key: CardFramePreferenceKey.self,
                        value: [id: geo.frame(in: .named("scroll"))])
    }
}

private func withMoveGesture<V: View>(_ view: V, for id: HomeCardID) -> some View {
    var decorated = AnyView(view)
    // 仅为被 ping 的目标卡片提供长按菜单以激活移动模式
    switch id {
    case .pingedGoal, .pingedContact:
        decorated = AnyView(decorated.contextMenu { cardContextMenu(for: id) })
    case .type:
        break
    }

    // 在移动模式下允许拖拽任意卡片，开始拖拽时自动切换为当前移动目标
    if moveModeEnabledForID != nil {
        return AnyView(decorated.highPriorityGesture(dragIfMoveEnabled(for: id)))
    } else {
        return decorated
    }
}

private func shouldUpdateCardFrames(_ newFrames: [HomeCardID: CGRect], comparedTo oldFrames: [HomeCardID: CGRect]) -> Bool {
    if newFrames.count != oldFrames.count { return true }
    let epsilon: CGFloat = 0.5
    for (key, newRect) in newFrames {
        guard let oldRect = oldFrames[key] else { return true }
        if abs(newRect.minY - oldRect.minY) > epsilon { return true }
        if abs(newRect.height - oldRect.height) > epsilon { return true }
        if abs(newRect.minX - oldRect.minX) > epsilon { return true }
    }
    return false
}

private func spanForCard(_ id: HomeCardID) -> Int {
    // 根据用户选择的尺寸返回跨列宽度
    return widthSpanForCard(id)
}

private func dragIfMoveEnabled(for id: HomeCardID) -> some Gesture {
    DragGesture(minimumDistance: 10)
        .onChanged { drag in
            // 仅在移动模式下响应拖拽；若当前拖拽的不是已选中的卡片，则切换目标
            guard moveModeEnabledForID != nil else { return }
            if moveModeEnabledForID != id {
                withAnimation(.interactiveSpring()) {
                    moveModeEnabledForID = id
                    draggingCardID = id
                }
            } else if draggingCardID != id {
                withAnimation(.interactiveSpring()) {
                    draggingCardID = id
                }
            }
            dragOffset = drag.translation
            reorderDuringDrag(for: id, translation: drag.translation)
        }
        .onEnded { _ in
            guard moveModeEnabledForID == id else { return }
            finalizeDrag(for: id)
            withAnimation(.interactiveSpring()) {
                moveModeEnabledForID = nil
            }
        }
}

private func reorderDuringDrag(for id: HomeCardID, translation: CGSize) {
    guard let fromIndex = cardOrderIDs.firstIndex(of: id), let originalFrame = cardFramesByID[id] else { return }
    let currentFrame = originalFrame.offsetBy(dx: 0, dy: translation.height)

    // 根据拖拽后卡片的 midY，计算它应插入的位置索引
    let otherIDs = cardOrderIDs.enumerated().filter { $0.offset != fromIndex }.map { $0.element }
    // 按当前快照中卡片的 minY 排序，构建线性顺序参考
    let sortedOthers: [HomeCardID] = otherIDs.sorted { a, b in
        let fa = cardFramesByID[a]?.minY ?? .greatestFiniteMagnitude
        let fb = cardFramesByID[b]?.minY ?? .greatestFiniteMagnitude
        return fa < fb
    }

    // 计算目标插入位置：找到 currentFrame.midY 应处于的相邻边界
    var targetIndex = 0
    for (idx, oid) in sortedOthers.enumerated() {
        if let frame = cardFramesByID[oid] {
            if currentFrame.midY > frame.midY { targetIndex = idx + 1 }
        }
    }

    // 将 targetIndex 映射回原数组的索引空间
    var newOrder = cardOrderIDs
    newOrder.remove(at: fromIndex)
    if targetIndex >= sortedOthers.count {
        newOrder.append(id)
    } else {
        // 找到在原数组中的插入点（使用对应 otherID 的当前索引）
        let anchorID = sortedOthers[targetIndex]
        if let anchorIndexInOriginal = newOrder.firstIndex(of: anchorID) {
            newOrder.insert(id, at: anchorIndexInOriginal)
        } else {
            newOrder.insert(id, at: targetIndex)
        }
    }

    // 若位置未变化，则不触发动画
    if newOrder != cardOrderIDs {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9, blendDuration: 0.2)) {
            cardOrderIDs = newOrder
        }
    }
}

@ViewBuilder
private func cardContextMenu(for id: HomeCardID) -> some View {
    let current = cardSizesByID[id] ?? defaultSizeForID(id)
    Group {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                moveModeEnabledForID = id
            }
        } label: {
            Label("move_position".localized, systemImage: "arrow.up.arrow.down")
        }

        Button {
            setCardSize(.small, for: id)
        } label: {
            Label("size_small_1x1".localized, systemImage: current == .small ? "checkmark.circle" : "circle")
        }
        Button {
            setCardSize(.medium, for: id)
        } label: {
            Label("size_medium_1x2".localized, systemImage: current == .medium ? "checkmark.circle" : "circle")
        }
        Button {
            setCardSize(.large, for: id)
        } label: {
            Label("size_large_2x2".localized, systemImage: current == .large ? "checkmark.circle" : "circle")
        }
    }
}

private func finalizeDrag(for id: HomeCardID) {
    withAnimation(.interactiveSpring()) {
        draggingCardID = nil
        dragOffset = .zero
    }
    saveCardOrderIDs()
}

private func cardFrameReader(for type: HomeCardType) -> some View {
    GeometryReader { geo in
        Color.clear
            .preference(key: CardFramePreferenceKey.self,
                        value: [HomeCardID.type(type): geo.frame(in: .named("scroll"))])
    }
}

// 仅在对应卡片处于“移动位置”模式时附加拖拽手势，避免影响滚动
@ViewBuilder
private func withMoveGesture<V: View>(_ view: V, for type: HomeCardType) -> some View {
    // 在移动模式下允许拖拽任意卡片，开始拖拽时自动切换为当前移动目标
    if moveModeEnabledForID != nil {
        view.highPriorityGesture(dragIfMoveEnabled(for: type))
    } else {
        view
    }
}

// （保留上方 ID 版本 shouldUpdateCardFrames 实现，删除重复声明）

// Masonry 跨列设置：个人信息与资产卡片占两列，其余占一列
private func spanForCard(_ type: HomeCardType) -> Int {
    switch type {
    case .profile, .asset:
        return 2
    default:
        return 1
    }
}

// 使用原生上下文菜单触发移动/调整大小，无需自定义长按手势

// 仅在启用了移动模式后允许拖拽
private func dragIfMoveEnabled(for type: HomeCardType) -> some Gesture {
    DragGesture(minimumDistance: 10)
        .onChanged { drag in
            let id = HomeCardID.type(type)
            // 仅在移动模式下响应拖拽；若当前拖拽的不是已选中的卡片，则切换目标
            guard moveModeEnabledForID != nil else { return }
            if moveModeEnabledForID != id {
                withAnimation(.interactiveSpring()) {
                    moveModeEnabledForID = id
                    draggingCardID = id
                }
            } else if draggingCardID != id {
                withAnimation(.interactiveSpring()) {
                    draggingCardID = id
                }
            }
            dragOffset = drag.translation
            reorderDuringDrag(for: id, translation: drag.translation)
        }
        .onEnded { _ in
            guard moveModeEnabledForID == HomeCardID.type(type) else { return }
            finalizeDrag(for: HomeCardID.type(type))
            withAnimation(.interactiveSpring()) {
                moveModeEnabledForID = nil
            }
        }
}

// 类型卡片暂不进行重排，仅支持位置预览拖拽

@ViewBuilder
private func cardContextMenu(for type: HomeCardType) -> some View {
    let id = HomeCardID.type(type)
    let current = cardSizesByID[id] ?? defaultSizeForID(id)
    Group {
        Button(action: {
            moveModeEnabledForID = id
        }) {
            Label("move_position".localized, systemImage: "arrow.up.and.down.and.arrow.left.and.right")
        }
        .buttonStyle(ScaleButtonStyle())
        Button(action: { setCardSize(.small, for: id) }) {
            Label("size_small_1x1".localized, systemImage: current == .small ? "checkmark.circle" : "circle")
        }
        .buttonStyle(ScaleButtonStyle())
        Button(action: { setCardSize(.medium, for: id) }) {
            Label("size_medium_1x2".localized, systemImage: current == .medium ? "checkmark.circle" : "circle")
        }
        .buttonStyle(ScaleButtonStyle())
        Button(action: { setCardSize(.large, for: id) }) {
            Label("size_large_2x2".localized, systemImage: current == .large ? "checkmark.circle" : "circle")
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 旧的类型排序持久化已移除，已改用基于 HomeCardID 的 cardOrderIDs

// 为标签生成一致的颜色
private func tagColor(for tag: String) -> Color {
    // 使用TagColorManager获取标签颜色，确保整个应用中标签颜色一致
    return TagColorManager.shared.getColor(for: tag)
}
    
    // 用户信息卡片
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 头像
                if !user.avatar.isEmpty, let uiImage = ImageUtility.loadImageFromAppDirectory(fileName: user.avatar) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 68)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(UIColor.systemBlue).opacity(0.3), Color(UIColor.systemBlue).opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color(UIColor.systemBlue).opacity(0.15), radius: 8, x: 0, y: 4)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 68)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(UIColor.systemBlue).opacity(0.3), Color(UIColor.systemBlue).opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color(UIColor.systemBlue).opacity(0.15), radius: 8, x: 0, y: 4)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // 用户名
                    Text(user.name)
                        .font(AppFont.pageTitle())
                        .foregroundColor(Color(UIColor.label))
                    
                    // 用户描述
                    Text(user.userDescription)
                        .font(AppFont.subtextMedium())
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineSpacing(2)
                        .lineLimit(3)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    // 详情按钮改为导航推入
                    if let firstUser = users.first {
                        NavigationLink(destination: UserEditView(user: firstUser)) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color(UIColor.systemGray))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer()
                }
                
            }

            // 标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(user.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .foregroundColor(.white)
                            // 可以添加图标
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(tagColor(for: tag))
                        .cornerRadius(12)
                    }
                }
                .padding(.vertical, 5)
            }

            // 自定义信息（仅在 2x2 大卡片显示部分）
            if (cardSizesByID[HomeCardID.type(.profile)] ?? defaultSizeForID(HomeCardID.type(.profile))) == .large {
                // 最近心情（仅 2×2 大卡片显示；来自最近三篇日记，复用心情卡片样式）
                if !latestDailyMoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "face.smiling")
                                .font(.title3)
                                .foregroundColor(Color(UIColor.systemYellow))
                            Text("recent_moods".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor.label))
                        }
                        HStack(spacing: 8) {
                            ForEach(latestDailyMoods.indices, id: \.self) { i in
                                Text(latestDailyMoods[i])
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .frame(height: 56)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("自定义信息")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.secondaryLabel))

                    if user.customInfos.isEmpty {
                        Text("暂无自定义信息")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    } else {
                        // 仅显示前几条，超出卡片将被容器裁剪隐藏
                        ForEach(Array(user.customInfos.prefix(6))) { info in
                            HStack(spacing: 8) {
                                Text(info.key)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                Text(":")
                                    .foregroundColor(Color(UIColor.systemGray))
                                Text(info.value)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.systemGray5).opacity(0.5), lineWidth: 0.5)
                )
        )
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 资产信息卡片
    private var assetSection: some View {
        NavigationLink(destination: AssetDetailView()) {
            assetCardContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var assetCardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 左侧标题
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGreen))
                    Text("home_card_asset_title".localized)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                HStack(spacing: 4) {                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.systemGray))
                }
            }
            
            // 资产详情
            HStack(spacing: 20) {
                // 现金
                VStack(alignment: .leading, spacing: 4) {
                    Text("cash".localized)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.cashAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // 其他资产
                VStack(alignment: .leading, spacing: 4) {
                    Text("other_assets".localized)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.otherAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // 负债
                VStack(alignment: .leading, spacing: 4) {
                    Text("debt".localized)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.debtAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemRed))
                }
                
                Spacer()
                
                // 右侧总资产
                HStack(spacing: 2) {
                    Text(String(format: "%.1f", asset.totalAssets))
                        .fontWeight(.heavy)
                        .foregroundColor(Color(UIColor.systemBlue))
                    Text("ten_thousand_unit".localized)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .font(AppFont.sectionTitle())
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.systemGray5).opacity(0.5), lineWidth: 0.5)
                )
        )
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 目标区域
    @State private var showingGoalPopup = false
    @State private var goalFilterExpanded: Bool = UserDefaults.standard.bool(forKey: "goalFilterExpanded")
    @State private var selectedGoalType: GoalType? = nil
    @State private var selectedImportance: GoalImportance? = nil
    @State private var selectedTags: Set<String> = []
    @State private var selectedYear: Int? = nil
    @State private var savedFilteredGoals: [Goal] = []
    @State private var searchText: String = UserDefaults.standard.string(forKey: "goalSearchText") ?? ""
    
    // 监听筛选条件变化
    private var goalFiltersChanged: Bool {
        // 这个计算属性用于触发 onChange 修饰符
        return true
    }
    
    // 加载保存的筛选条件 - 优化版本
    private func loadSavedGoalFilters() {
        let defaults = UserDefaults.standard
        
        // 批量获取所有需要的值，减少UserDefaults访问次数
        let keys = ["goalFilterExpanded", "goalSearchText", "selectedGoalType", "selectedImportance", "goalFilterTags", "selectedYear"]
        let values = defaults.dictionaryRepresentation().filter { keys.contains($0.key) }
        
        // 加载筛选条件
        goalFilterExpanded = values["goalFilterExpanded"] as? Bool ?? false
        searchText = values["goalSearchText"] as? String ?? ""
        
        // 加载目标类型
        if let typeString = values["selectedGoalType"] as? String,
           let type = GoalType(rawValue: typeString) {
            selectedGoalType = type
        } else {
            selectedGoalType = nil
        }
        
        // 加载优先级
        if let importanceInt = values["selectedImportance"] as? Int,
           let importance = GoalImportance(rawValue: importanceInt) {
            selectedImportance = importance
        } else {
            selectedImportance = nil
        }

        // 加载标签
        if let tagArray = values["goalFilterTags"] as? [String] {
            selectedTags = Set(tagArray)
        } else {
            selectedTags = []
        }
        
        // 加载年份筛选
        if let year = values["selectedYear"] as? Int {
            selectedYear = year
        } else {
            selectedYear = nil
        }
        
        // 应用筛选条件到目标列表
        updateFilteredGoals()
    }
    
    // 更新筛选后的目标列表 - 优化版本
    private func updateFilteredGoals() {
        // 如果没有任何筛选条件，直接使用所有目标
        if selectedGoalType == nil && selectedImportance == nil && searchText.isEmpty && selectedTags.isEmpty && selectedYear == nil {
            savedFilteredGoals = goals
            return
        }
        
        // 优化筛选逻辑，避免不必要的计算
        savedFilteredGoals = goals.filter { goal in
            // 先检查类型和优先级（计算成本较低）
            if let type = selectedGoalType, goal.goalType != type {
                return false
            }
            
            if let importance = selectedImportance, goal.goalImportance != importance {
                return false
            }

            // 检查标签
            if !selectedTags.isEmpty {
                let matchesTag = goal.tags.contains { selectedTags.contains($0) }
                if !matchesTag { return false }
            }
            
            // 检查年份
            if let year = selectedYear, let dueDate = goal.dueDate {
                let calendar = Calendar.current
                let goalYear = calendar.component(.year, from: dueDate)
                if goalYear != year {
                    return false
                }
            }
            
            // 最后检查搜索文本（计算成本较高）
            if !searchText.isEmpty {
                return goal.name.localizedCaseInsensitiveContains(searchText) ||
                       goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                       goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
            
            return true
        }
    }

    // MARK: - 被Ping的目标卡片
    private var pingedGoalSection: some View {
        ForEach(pingManager.allPingedGoalIDs, id: \.self) { goalID in
            if let goal = goals.first(where: { $0.id == goalID }) {
                // 直接显示目标卡片，添加取消Ping按钮
                ZStack(alignment: .topTrailing) {
                    // 使用简洁的HomeGoalCard
                    HomeGoalCard(goal: goal)
                        .overlay(
                            // 右上角添加取消Ping标记
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        pingManager.unping(goalID: goalID)
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "pin.slash.fill")
                                                .font(.system(size: 14))
                                            Text("取消Ping")
                                                .font(AppFont.subtextMedium())
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(UIColor.systemOrange))
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                    .padding(12)
                                }
                                Spacer()
                            }
                        )
                }
            }
        }
    }
    
    private var goalSection: some View {
        Button(action: {
            // 显示目标弹窗
            showingGoalPopup = true
        }) {
            goalCardContent
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingGoalPopup) {
            GoalPopupView(
                goalFilterExpanded: $goalFilterExpanded,
                selectedGoalType: $selectedGoalType,
                selectedImportance: $selectedImportance,
                savedFilteredGoals: $savedFilteredGoals,
                searchText: $searchText,
                selectedTags: $selectedTags,
                selectedYear: $selectedYear
            )
        }
    }
    
    private var goalCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemBlue))
                Text("近期目标")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                
                // 目标数量
                HStack(spacing: 4) {
                    Text("\(goals.count)")
                        .font(AppFont.subtextMedium())
                        .foregroundColor(Color(UIColor.systemBlue))
                    Text("个目标")
                        .font(AppFont.subtextMedium())
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(AppFont.assist())
                    .foregroundColor(Color(UIColor.systemGray))
            }
            
            // 确定要显示的目标列表：如果有保存的筛选结果则显示筛选结果，否则显示所有目标
            let goalsToDisplay = !savedFilteredGoals.isEmpty ? savedFilteredGoals : goals
            
            if goalsToDisplay.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Text("暂无目标")
                        .font(AppFont.bodyMedium())
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Button(action: {
                        // 跳转到目标页面
                        selectedTab = 1
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("添加目标")
                                .font(AppFont.subtextMedium())
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
            } else {
                // 目标列表 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(goalsToDisplay.prefix(3)) { goal in
                            VStack(alignment: .leading, spacing: 10) {
                                // 目标名称和优先级
                                HStack {
                                    Image(systemName: goal.goalImportance.iconName)
                                        .foregroundColor(goal.goalImportance.color)
                                        .font(.system(size: 14))
                                    
                                    Text(goal.name)
                                        .font(AppFont.subtextMedium())
                                        .lineLimit(1)
                                        .foregroundColor(Color(UIColor.label))
                                }
                                
                                // 完成状态
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(goal.progress >= 1.0 ? "已完成" : "进行中")
                                            .font(AppFont.assistMedium())
                                            .foregroundColor(goal.progress >= 1.0 ? Color(UIColor.systemGreen) : Color(UIColor.systemBlue))
                                        
                                        Spacer()
                                        
                                        // 目标类型标签
                                        Text(goal.goalType.rawValue)
                                            .font(AppFont.badge())
                                            .foregroundColor(Color(UIColor.systemGray))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(UIColor.systemGray6))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .frame(width: 150, height: 80)
                            .padding(16)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                        }
                        
                        // 查看更多按钮
                        if goalsToDisplay.count > 3 {
                            Button(action: {
                                showingGoalPopup = true
                            }) {
                                VStack(spacing: 10) {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(AppFont.hero())
                                        .foregroundColor(Color(UIColor.systemBlue))

                                    Text("查看更多")
                                        .font(AppFont.subtextMedium())
                                        .foregroundColor(Color(UIColor.systemBlue))
                                }
                                .frame(width: 100, height: 80)
                                .padding(16)
                                .background(Color(UIColor.systemBlue).opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
                .frame(height: 140) // 增加高度以适应卡片
            }
            
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // 心情区域 - 扁平化设计
    private var moodSection: some View {
        Button(action: {
            // 这里可以添加心情详情页面的跳转
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemYellow))
                    Text("心情")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                // 心情图标 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<moods.count, id: \.self) { index in
                            Image(systemName: getMoodIcon(for: index))
                                .font(.system(size: 24))
                                .foregroundColor(getMoodColor(for: index))
                                .frame(width: 44, height: 44)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                }
                .frame(height: 56)
            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 成就展示区域
    private var achievementSection: some View {
        NavigationLink(destination: AchievementDetailView()) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemYellow))
                    Text("home_card_achievement_title".localized)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(AppFont.assist())
                        .foregroundColor(Color(UIColor.systemGray))
                }
                // 置顶子任务展示（类似成就中心）
                if showPinnedSubtasksCard && !pinnedSubtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("置顶任务")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        let idForSize = HomeCardID.type(.achievement)
                        let size = cardSizesByID[idForSize] ?? defaultSizeForID(idForSize)
                        let displayCount: Int = {
                            switch size {
                            case .small: return 2
                            case .medium: return 6
                            case .large: return 12
                            }
                        }()
                        ForEach(Array(pinnedSubtasks.prefix(displayCount)), id: \.id) { task in
                            HStack {
                                Image(systemName: task.status == .done ? "checkmark.circle.fill" : (task.status == .inProgress ? "minus.circle.fill" : "circle"))
                                    .foregroundColor(task.status == .done ? Color(UIColor.systemGreen) : (task.status == .inProgress ? Color(UIColor.systemBlue) : Color(UIColor.systemGray)))
                                Text(task.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { unpin(task: task) }) {
                                    Image(systemName: "star.slash")
                                        .foregroundColor(Color(UIColor.systemBlue))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: Color(UIColor.label).opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                // 根据卡片尺寸展示最多 2/6/12 个成就
                let idForSize = HomeCardID.type(.achievement)
                let size = cardSizesByID[idForSize] ?? defaultSizeForID(idForSize)
                let displayCount: Int = {
                    switch size {
                        case .small: return 2   // 1×1 显示 2 条
                        case .medium: return 6  // 1×2 显示 6 条
                        case .large: return 12  // 2×2 显示 12 条
                    }
                }()
                // 使用带有“成就”标签的目标作为数据源（直接展示前 N 条）
                let recentGoals = Array(achievementGoals.prefix(displayCount))

                if recentGoals.isEmpty {
                    Text("empty_no_achievements".localized)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(recentGoals) { goal in
                            HStack {
                                Text(goal.name.isEmpty ? "unnamed_achievement".localized : goal.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: Color(UIColor.label).opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                    }
                }

            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var achievementCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemYellow))
                Text("home_card_achievement_title".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                
                // 详情按钮（替换铅笔按钮为右上角箭头）
                Button(action: { showingAchievementDetail = true }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 36, height: 36)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.systemBlue).opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
            
            // 成就图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(achievementGoals.prefix(8)) { goal in
                        VStack(spacing: 6) {
                                Text(goal.name)
                                    .font(AppFont.captionMedium())
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                    .frame(width: 80)
                            
                            Text(BuiltInTags.achievement)
                                .font(AppFont.badge())
                                .foregroundColor(tagColor(for: BuiltInTags.achievement))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tagColor(for: BuiltInTags.achievement).opacity(0.12))
                                .cornerRadius(6)
                        }
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(height: 80) // 增加高度以适应标签
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 待改进区域 - 扁平化设计
    private var improvementSection: some View {
        NavigationLink(destination: AnxietyDetailView()) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemOrange))
                    Text("home_card_anxiety_title".localized)
                        .font(AppFont.sectionTitle())
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(AppFont.assist())
                        .foregroundColor(Color(UIColor.systemGray))
                }
                // 参考“成就”卡片：根据卡片尺寸展示最多 2/6/12 条焦虑
                // 使用现有的改进卡片类型（improvement）作为尺寸 ID
                let idForSize = HomeCardID.type(.improvement)
                let size = cardSizesByID[idForSize] ?? defaultSizeForID(idForSize)
                let displayCount: Int = {
                    switch size {
                    case .small: return 2   // 1×1 显示 2 条
                    case .medium: return 6  // 1×2 显示 6 条
                    case .large: return 12  // 2×2 显示 12 条
                    }
                }()
                let recentAnxieties = Array(anxietyGoals.prefix(displayCount))

                if recentAnxieties.isEmpty {
                    Text("empty_no_anxiety".localized)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(recentAnxieties) { goal in
                            HStack {
                                Text(goal.name.isEmpty ? "unnamed_anxiety".localized : goal.name)
                                    .font(AppFont.subtextMedium())
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: Color(UIColor.label).opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 置顶子任务展示区域（独立卡片）
    private var pinnedSubtasksSection: some View {
        NavigationLink(destination: PinnedSubtasksDetailView()) {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemYellow))
                Text("置顶任务")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            let idForSize = HomeCardID.type(.pinnedSubtasks)
            let size = cardSizesByID[idForSize] ?? defaultSizeForID(idForSize)
            let displayCount: Int = {
                switch size {
                case .small: return 2
                case .medium: return 6
                case .large: return 12
                }
            }()
            let items = Array(pinnedSubtasks.prefix(displayCount))
            if items.isEmpty {
                Text("empty_no_pinned_subtasks".localized)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.id) { task in
                        HStack {
                            Image(systemName: task.status == .done ? "checkmark.circle.fill" : (task.status == .inProgress ? "minus.circle.fill" : "circle"))
                                .foregroundColor(task.status == .done ? Color(UIColor.systemGreen) : (task.status == .inProgress ? Color(UIColor.systemBlue) : Color(UIColor.systemGray)))
                            Text(task.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(UIColor.label))
                                .lineLimit(1)
                            Spacer()
                            Button(action: { unpin(task: task) }) {
                                Image(systemName: "star.slash")
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 最近焦虑统计卡片
    private var anxietyStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                statTile(title: "总数", value: anxietyGoals.count, color: Color(UIColor.systemOrange))
                statTile(title: "本周新增", value: recentAnxietyWeeklyCount, color: Color(UIColor.systemBlue))
                statTile(title: "本月新增", value: recentAnxietyMonthlyCount, color: Color(UIColor.systemGreen))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("近7天创建趋势")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                miniBarChart(values: last7DaysAnxietyCounts, barColor: Color(UIColor.systemOrange))
            }
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // 统计瓦片（局部复用）
    private func statTile(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(AppFont.sectionTitle())
                .foregroundColor(color)
            Text(title)
                .font(AppFont.caption())
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }

    // 迷你柱状图（局部复用）
    private func miniBarChart(values: [Int], barColor: Color) -> some View {
        let maxV = max(values.max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(values.indices, id: \.self) { i in
                let v = values[i]
                let h = CGFloat(v) / CGFloat(maxV)
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: 12, height: max(8, 36 * h))
                    .opacity(v == 0 ? 0.35 : 1.0)
            }
        }
        .frame(height: 40)
    }
    

    
    // 成就图标现在直接使用 Achievement 模型中的 emoji 属性
    
    // 获取心情图标的辅助函数
    func getMoodIcon(for index: Int) -> String {
        let moodIcons = ["face.smiling"]
        return index < moodIcons.count ? moodIcons[index] : "face.dashed"
    }
    
    // 获取心情颜色的辅助函数
    func getMoodColor(for index: Int) -> Color {
        let moodColors = [
            Color(UIColor.systemYellow),  // 开心
            Color(UIColor.systemBlue),    // 悲伤
            Color(UIColor.systemRed),     // 愤怒
            Color(UIColor.systemGray),    // 疲倦
            Color(UIColor.systemPurple),  // 思考
            Color(UIColor.systemOrange)   // 酷
        ]
        return index < moodColors.count ? moodColors[index] : Color(UIColor.systemGray)
    }

}

// 主页专用的简洁目标卡片视图：严格 1×1 / 1×2 / 2×2 尺寸，响应式内容与精确裁剪背景
struct HomeGoalCard: View {
    let goal: Goal
    var cardWidth: CGFloat?
    var isFixedHeightContainer: Bool = false

    init(goal: Goal, cardWidth: CGFloat? = nil, isFixedHeightContainer: Bool = false) {
        self.goal = goal
        self.cardWidth = cardWidth
        self.isFixedHeightContainer = isFixedHeightContainer
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var progressColor: Color {
        // 统一为系统蓝色，覆盖原有按进度动态变色逻辑
        return Color(UIColor.systemBlue)
    }

    // Masonry 网格的高度规范（与 HomeView 中保持一致）
    private let smallRowHeight: CGFloat = 160
    private let gridSpacing: CGFloat = 16
    private var largeRowHeight: CGFloat { smallRowHeight * 2 + gridSpacing } // 2 行高度 + 一次间距

    private enum SizeClass { case small, medium, large }

    private func sizeClass(for size: CGSize) -> SizeClass {
        if size.height >= largeRowHeight - 0.5 { return .large }
        // 同为一行高度：通过宽度区分 1×1 与 1×2
        if size.width > 480 { return .medium } else { return .small }
    }

    private struct CardStyle {
        let nameSize: CGFloat
        let descSize: CGFloat
        let padding: CGFloat
        let spacing: CGFloat
        let progressHeight: CGFloat
        let nameLines: Int
        let descLines: Int
        let overlayOpacity: Double
    }

    private func style(for size: CGSize) -> CardStyle {
        switch sizeClass(for: size) {
        case .small:
            return CardStyle(
                nameSize: 16, descSize: 12, padding: 12, spacing: 6, progressHeight: 4,
                nameLines: 2, descLines: 1, overlayOpacity: 0.5
            )
        case .medium:
            return CardStyle(
                nameSize: 18, descSize: 13, padding: 16, spacing: 8, progressHeight: 5,
                nameLines: 2, descLines: 2, overlayOpacity: 0.5
            )
        case .large:
            return CardStyle(
                nameSize: 20, descSize: 14, padding: 16, spacing: 10, progressHeight: 6,
                nameLines: 3, descLines: 3, overlayOpacity: 0.5
            )
        }
    }

    @ViewBuilder
    private func backgroundView(for size: CGSize) -> some View {
        if let imageName = goal.backgroundImage {
            let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
            let uiImage = UIImage(named: imageName) ?? UIImage(contentsOfFile: fileURL.path)
            if let ui = uiImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .clipped() // 精确裁剪并隐藏超出部分
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .clipped()
            }
        } else {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipped()
        }
    }

    var body: some View {
        NavigationLink(destination: GoalDetailView(goal: goal)) {
            GeometryReader { geo in
                let size = geo.size
                let st = style(for: size)
                ZStack(alignment: .topLeading) {
                    backgroundView(for: size)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Rectangle()
                        .fill(Color(UIColor.systemBackground).opacity(st.overlayOpacity))
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: st.spacing) {
                         HStack {
                             Spacer()
                            Text("目标")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
                                )
                         }

                        Spacer(minLength: st.spacing)

                        Text(goal.name)
                            .font(.system(size: st.nameSize, weight: .bold))
                            .foregroundColor(Color(UIColor.label))
                            .lineLimit(st.nameLines)
                            .minimumScaleFactor(0.92)

                        if !goal.goalDescription.isEmpty {
                            Text(goal.goalDescription)
                                .font(.system(size: st.descSize))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .lineLimit(st.descLines)
                                .minimumScaleFactor(0.92)
                        }

                        Spacer(minLength: st.spacing)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("进度")
                                    .font(.system(size: max(11, st.descSize - 1), weight: .medium))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                Spacer()
                                Text("\(Int(goal.progress * 100))%")
                                    .font(.system(size: max(11, st.descSize - 1), weight: .semibold))
                                    .foregroundColor(progressColor)
                            }

                            ProgressView(value: goal.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                                .frame(height: st.progressHeight)
                        }
                    }
                    .padding(st.padding)
                }
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .clipped() // 严格隐藏超出边界的内容
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(UIColor.label).opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 置顶子任务管理页
struct PinnedSubtasksDetailView: View {
    @Query(sort: \Goal.createTime, order: .reverse) private var goals: [Goal]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var refreshID = UUID()
    @State private var statusFilter: TaskStatus? = nil
    @State private var searchText: String = ""

    private var pinnedTaskIDs: [UUID] {
        let arr = UserDefaults.standard.stringArray(forKey: "PinnedSubtaskIDs") ?? []
        return arr.compactMap { UUID(uuidString: $0) }
    }
    private var pinnedSubtasks: [GoalTask] {
        let set = Set(pinnedTaskIDs)
        var result: [GoalTask] = []
        for g in goals where !g.isDeleted {
            for t in g.tasks {
                if set.contains(t.id) { result.append(t) }
            }
        }
        return result
    }
    private var filteredSubtasks: [GoalTask] {
        let base = pinnedSubtasks
        let byStatus = statusFilter == nil ? base : base.filter { $0.status == statusFilter }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return byStatus }
        return byStatus.filter { $0.title.localizedCaseInsensitiveContains(searchText) || ($0.goal?.name.localizedCaseInsensitiveContains(searchText) ?? false) }
    }
    private func unpin(_ task: GoalTask) {
        var arr = UserDefaults.standard.stringArray(forKey: "PinnedSubtaskIDs") ?? []
        if let idx = arr.firstIndex(of: task.id.uuidString) {
            arr.remove(at: idx)
            UserDefaults.standard.set(arr, forKey: "PinnedSubtaskIDs")
            refreshID = UUID()
        }
    }

    private func toggleStatus(_ task: GoalTask) {
        let wasDone = task.isCompleted
        switch task.status {
        case .todo: task.status = .inProgress
        case .inProgress: task.status = .done
        case .done: task.status = .todo
        }
        task.isCompleted = (task.status == .done)
        do { try modelContext.save() } catch { }
        refreshID = UUID()
    }

    var body: some View {
        List {
            Section {
                Picker("", selection: Binding(
                    get: { statusFilter ?? TaskStatus.todo },
                    set: { newValue in statusFilter = newValue == TaskStatus.todo ? nil : newValue }
                )) {
                    Text("task_status_all".localized).tag(TaskStatus.todo)
                    Text("task_status_in_progress".localized).tag(TaskStatus.inProgress)
                    Text("task_status_done".localized).tag(TaskStatus.done)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                if filteredSubtasks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGray))
                        Text("empty_no_pinned_subtasks".localized)
                            .font(AppFont.subtext())
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                } else {
                    ForEach(filteredSubtasks, id: \.id) { task in
                        HStack(spacing: 12) {
                            Button { toggleStatus(task) } label: {
                                ZStack {
                                    Circle()
                                        .stroke((task.status == .done || task.status == .inProgress) ? Color.clear : Color(UIColor.systemGray3), lineWidth: 1.5)
                                        .frame(width: 22, height: 22)
                                    if task.status == .done {
                                        Circle().fill(Color(UIColor.systemBlue)).frame(width: 22, height: 22)
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                    } else if task.status == .inProgress {
                                        Circle().fill(Color(UIColor.systemBlue)).frame(width: 22, height: 22)
                                        Image(systemName: "minus").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(AppFont.bodyMedium())
                                    .foregroundColor(task.status == .done ? Color(UIColor.systemGray) : Color(UIColor.label))
                                    .strikethrough(task.status == .done)
                                    .lineLimit(2)
                                if let name = task.goal?.name, !name.isEmpty {
                                    Text(name)
                                        .font(AppFont.assist())
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                            }
                            Spacer()
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { unpin(task) } label: { Text("unpin_from_home".localized) }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(UIColor.systemYellow))
                    Text("pinned_subtasks_manage_title".localized)
                        .font(AppFont.sectionTitle())
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    Text("\(filteredSubtasks.count)")
                        .font(AppFont.assist())
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.systemGray5).opacity(0.6))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
            }
            .headerProminence(.increased)
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
        .animation(.spring(response: 0.24, dampingFraction: 0.9), value: statusFilter)
        .animation(.spring(response: 0.24, dampingFraction: 0.9), value: searchText)
        .navigationBarTitle(Text("pinned_subtasks_manage_title".localized), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("back".localized) { dismiss() }
                    .tint(Color(UIColor.systemBlue))
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .modelContainer(for: Item.self, inMemory: true)
    }
}
