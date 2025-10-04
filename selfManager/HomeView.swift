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
    @State private var rotation: Double = -1.2
    @State private var sway: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive ? rotation : 0))
            .offset(x: isActive ? sway : 0)
            .onAppear {
                if isActive {
                    withAnimation(Animation.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) {
                        rotation = 1.2
                        sway = 0.8
                    }
                }
            }
            .onChange(of: isActive) { active in
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
        case pingedGoals
        case goals
        case moodAchievement // 心情+成就并排区域作为一个卡片
        case improvement
    }

    @State private var cardOrder: [HomeCardType] = []
    @State private var draggingCard: HomeCardType? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardFrames: [HomeCardType: CGRect] = [:]
    // 移动模式与菜单状态
    @State private var moveModeEnabledFor: HomeCardType? = nil
    @State private var expandedCards: Set<HomeCardType> = []
    // 最近一次交换时的拖拽位移基线，避免重复计算导致跳动
    @State private var lastSwapTranslationY: CGFloat = 0

    private struct CardFramePreferenceKey: PreferenceKey {
        static var defaultValue: [HomeCardType: CGRect] = [:]
        static func reduce(value: inout [HomeCardType: CGRect], nextValue: () -> [HomeCardType: CGRect]) {
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
        NavigationStack(path: navigationManager.getNavigationPath(for: 0)) {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部间距
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40) // 将高度从 140 减小到 80
                        
                        // 主页卡片渲染（支持长按拖拽排序）
                        ForEach(cardOrder, id: \.self) { type in
                            renderCard(type)
                        }
                        .animation(.interactiveSpring(), value: cardOrder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                    .onPreferenceChange(CardFramePreferenceKey.self) { frames in
                        // 为避免“Bound preference ... update multiple times per frame”警告：
                        // 在进入移动模式或拖拽/晃动期间不更新 cardFrames，使用进入前的静态快照即可。
                        guard moveModeEnabledFor == nil && draggingCard == nil else { return }
                        if shouldUpdateCardFrames(frames, comparedTo: cardFrames) {
                            cardFrames = frames
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .coordinateSpace(name: "scroll")
                
                // 悬浮的顶部标题栏
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        // 侧边栏按钮
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
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("  我")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.label))
                        }
                        
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
        }

        .onAppear {
            // 在视图加载时应用保存的筛选条件，但避免重复加载

            if savedFilteredGoals.isEmpty {
                loadSavedGoalFilters()
            }
            // 加载主页卡片排序
            loadCardOrder()
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

// MARK: - 拖拽排序：渲染卡片及交互逻辑
@ViewBuilder
private func renderCard(_ type: HomeCardType) -> some View {
    let isDragging = (draggingCard == type)
    switch type {
    case .profile:
        withMoveGesture(
            userProfileSection
                .background(cardFrameReader(for: type))
                .offset(isDragging ? dragOffset : .zero)
                .jiggle(moveModeEnabledFor == type && draggingCard == nil)
                .scaleEffect(isDragging ? 1.02 : (expandedCards.contains(type) ? 1.04 : 1.0))
                .zIndex(isDragging ? 20 : 0)
                .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                .contentShape(Rectangle())
                .contextMenu { cardContextMenu(for: type) }
            , for: type)
            .sheet(isPresented: $showingEdit) {
                UserEditView(user: user)
            }
    case .asset:
        withMoveGesture(
            assetSection
                .background(cardFrameReader(for: type))
                .offset(isDragging ? dragOffset : .zero)
                .jiggle(moveModeEnabledFor == type && draggingCard == nil)
                .scaleEffect(isDragging ? 1.02 : (expandedCards.contains(type) ? 1.04 : 1.0))
                .zIndex(isDragging ? 20 : 0)
                .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                .contentShape(Rectangle())
                .contextMenu { cardContextMenu(for: type) }
            , for: type)
    case .pingedGoals:
        withMoveGesture(
            pingedGoalSection
                .background(cardFrameReader(for: type))
                .offset(isDragging ? dragOffset : .zero)
                .jiggle(moveModeEnabledFor == type && draggingCard == nil)
                .scaleEffect(isDragging ? 1.02 : (expandedCards.contains(type) ? 1.04 : 1.0))
                .zIndex(isDragging ? 20 : 0)
                .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                .contentShape(Rectangle())
                .contextMenu { cardContextMenu(for: type) }
            , for: type)
    case .goals:
        withMoveGesture(
            goalSection
                .background(cardFrameReader(for: type))
                .offset(isDragging ? dragOffset : .zero)
                .jiggle(moveModeEnabledFor == type && draggingCard == nil)
                .scaleEffect(isDragging ? 1.02 : (expandedCards.contains(type) ? 1.04 : 1.0))
                .zIndex(isDragging ? 20 : 0)
                .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                .contentShape(Rectangle())
                .contextMenu { cardContextMenu(for: type) }
            , for: type)
    case .moodAchievement:
        withMoveGesture(
            HStack(spacing: 16) {
                moodSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                achievementSection
                    .frame(maxWidth: .infinity)
            }
            .background(cardFrameReader(for: type))
            .offset(isDragging ? dragOffset : .zero)
            .jiggle(moveModeEnabledFor == type && draggingCard == nil)
            .scaleEffect(isDragging ? 1.02 : (expandedCards.contains(type) ? 1.04 : 1.0))
            .zIndex(isDragging ? 20 : 0)
            .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
            .contentShape(Rectangle())
            .contextMenu { cardContextMenu(for: type) }
        , for: type)
    case .improvement:
        withMoveGesture(
            improvementSection
                .background(cardFrameReader(for: type))
                .offset(isDragging ? dragOffset : .zero)
                .jiggle(moveModeEnabledFor == type && draggingCard == nil)
                .scaleEffect(isDragging ? 1.02 : (expandedCards.contains(type) ? 1.04 : 1.0))
                .zIndex(isDragging ? 20 : 0)
                .shadow(color: Color(UIColor.label).opacity(isDragging ? 0.12 : 0.06), radius: isDragging ? 10 : 8, x: 0, y: isDragging ? 6 : 4)
                .contentShape(Rectangle())
                .contextMenu { cardContextMenu(for: type) }
            , for: type)
    }
}

private func cardFrameReader(for type: HomeCardType) -> some View {
    GeometryReader { geo in
        Color.clear
            .preference(key: CardFramePreferenceKey.self,
                        value: [type: geo.frame(in: .named("scroll"))])
    }
}

// 仅在对应卡片处于“移动位置”模式时附加拖拽手势，避免影响滚动
@ViewBuilder
private func withMoveGesture<V: View>(_ view: V, for type: HomeCardType) -> some View {
    if moveModeEnabledFor == type {
        view.highPriorityGesture(dragIfMoveEnabled(for: type))
    } else {
        view
    }
}

// 仅当位置或高度发生明显变化时更新 cardFrames，避免每帧微小变化造成多次更新
private func shouldUpdateCardFrames(_ newFrames: [HomeCardType: CGRect], comparedTo oldFrames: [HomeCardType: CGRect]) -> Bool {
    if newFrames.count != oldFrames.count { return true }
    let epsilon: CGFloat = 0.5
    for (key, newRect) in newFrames {
        guard let oldRect = oldFrames[key] else { return true }
        if abs(newRect.minY - oldRect.minY) > epsilon { return true }
        if abs(newRect.height - oldRect.height) > epsilon { return true }
    }
    return false
}

// 使用原生上下文菜单触发移动/调整大小，无需自定义长按手势

// 仅在启用了移动模式后允许拖拽
private func dragIfMoveEnabled(for type: HomeCardType) -> some Gesture {
    DragGesture(minimumDistance: 10)
        .onChanged { drag in
            guard moveModeEnabledFor == type else { return }
            if draggingCard != type {
                withAnimation(.interactiveSpring()) {
                    draggingCard = type
                }
                // 开始拖拽时重置交换基线
                lastSwapTranslationY = 0
            }
            dragOffset = drag.translation
            reorderIfNeeded(for: type, translation: drag.translation)
        }
        .onEnded { _ in
            guard moveModeEnabledFor == type else { return }
            finalizeDrag(for: type)
            withAnimation(.interactiveSpring()) {
                moveModeEnabledFor = nil
            }
            lastSwapTranslationY = 0
        }
}

private func reorderIfNeeded(for type: HomeCardType, translation: CGSize) {
    guard let fromIndex = cardOrder.firstIndex(of: type), let original = cardFrames[type] else { return }
    // 相对最近一次交换的有效位移，降低频繁交换导致的跳动
    let dy = translation.height - lastSwapTranslationY
    // 当前卡片随拖拽产生的临时位置（用于计算与相邻卡片的重叠）
    let currentFrame = original.offsetBy(dx: 0, dy: dy)

    // 只与相邻卡片比较并一步交换，避免一次跨越多卡片造成大幅跳动
    let hysteresis: CGFloat = 0.25 // 至少重叠对方高度的25%才触发交换

    if dy > 0 {
        // 向下拖动：与下一个卡片比较
        let nextIndex = fromIndex + 1
        if nextIndex < cardOrder.count, let nextFrame = cardFrames[cardOrder[nextIndex]] {
            let overlap = currentFrame.intersection(nextFrame).height
            let shouldSwap = overlap > nextFrame.height * hysteresis || currentFrame.midY > nextFrame.midY
            if shouldSwap {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9, blendDuration: 0.2)) {
                    var newOrder = cardOrder
                    newOrder.swapAt(fromIndex, nextIndex)
                    cardOrder = newOrder
                }
                // 更新交换基线，下一次以当前位移为基准计算
                lastSwapTranslationY = translation.height
            }
        }
    } else if dy < 0 {
        // 向上拖动：与上一个卡片比较
        let prevIndex = fromIndex - 1
        if prevIndex >= 0, let prevFrame = cardFrames[cardOrder[prevIndex]] {
            let overlap = currentFrame.intersection(prevFrame).height
            let shouldSwap = overlap > prevFrame.height * hysteresis || currentFrame.midY < prevFrame.midY
            if shouldSwap {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9, blendDuration: 0.2)) {
                    var newOrder = cardOrder
                    newOrder.swapAt(fromIndex, prevIndex)
                    cardOrder = newOrder
                }
                // 更新交换基线
                lastSwapTranslationY = translation.height
            }
        }
    }
}

private func finalizeDrag(for type: HomeCardType) {
    withAnimation(.interactiveSpring()) {
        draggingCard = nil
        dragOffset = .zero
    }
    saveCardOrder()
}

@ViewBuilder
private func cardContextMenu(for type: HomeCardType) -> some View {
    Group {
        Button(action: {
            moveModeEnabledFor = type
        }) {
            Label("移动位置", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
        }
        Button(action: {
            if expandedCards.contains(type) {
                expandedCards.remove(type)
            } else {
                expandedCards.insert(type)
            }
        }) {
            Label("调整大小", systemImage: "arrow.up.left.and.arrow.down.right")
        }
    }
}

// MARK: - 排序持久化
private let cardOrderKey = "home.card.order.v1"

private func defaultCardOrder() -> [HomeCardType] {
    [.profile, .asset, .pingedGoals, .goals, .moodAchievement, .improvement]
}

private func loadCardOrder() {
    if let raw = UserDefaults.standard.array(forKey: cardOrderKey) as? [String] {
        let mapped = raw.compactMap { HomeCardType(rawValue: $0) }
        if !mapped.isEmpty {
            cardOrder = mapped
            return
        }
    }
    cardOrder = defaultCardOrder()
}

private func saveCardOrder() {
    UserDefaults.standard.set(cardOrder.map { $0.rawValue }, forKey: cardOrderKey)
}

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
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                    
                    // 用户描述
                    Text(user.userDescription)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineSpacing(2)
                        .lineLimit(3)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    // 详情按钮
                    Button(action: { showingEdit = true }) {
                        ZStack {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color(UIColor.systemGray))
                        }
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
        }
        .padding(20)
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
        Button(action: {
            showingAssetDetail = true
        }) {
            assetCardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAssetDetail) {
            NavigationStack {
                AssetDetailView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var assetCardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 左侧标题
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGreen))
                    Text("我的资产")
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
                    Text("现金")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.cashAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // 其他资产
                VStack(alignment: .leading, spacing: 4) {
                    Text("其他")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.otherAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // 负债
                VStack(alignment: .leading, spacing: 4) {
                    Text("负债")
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
                    Text("W")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .padding(20)
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
        let keys = ["goalFilterExpanded", "goalSearchText", "selectedGoalType", "selectedImportance"]
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
        
        // 应用筛选条件到目标列表
        updateFilteredGoals()
    }
    
    // 更新筛选后的目标列表 - 优化版本
    private func updateFilteredGoals() {
        // 如果没有任何筛选条件，直接使用所有目标
        if selectedGoalType == nil && selectedImportance == nil && searchText.isEmpty {
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
                    // 使用完整的GoalCard而非SimplifiedGoalCard
                    GoalCard(goal: goal)
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
                                                .font(.system(size: 14, weight: .medium))
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingGoalPopup) {
            GoalPopupView(
                goalFilterExpanded: $goalFilterExpanded,
                selectedGoalType: $selectedGoalType,
                selectedImportance: $selectedImportance,
                savedFilteredGoals: $savedFilteredGoals,
                searchText: $searchText
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemBlue))
                    Text("个目标")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(UIColor.systemGray))
            }
            
            // 确定要显示的目标列表：如果有保存的筛选结果则显示筛选结果，否则显示所有目标
            let goalsToDisplay = !savedFilteredGoals.isEmpty ? savedFilteredGoals : goals
            
            if goalsToDisplay.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Text("暂无目标")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Button(action: {
                        // 跳转到目标页面
                        selectedTab = 1
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("添加目标")
                                .font(.system(size: 14, weight: .medium))
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
                                        .font(.system(size: 15, weight: .medium))
                                        .lineLimit(1)
                                        .foregroundColor(Color(UIColor.label))
                                }
                                
                                // 完成状态
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(goal.progress >= 1.0 ? "已完成" : "进行中")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(goal.progress >= 1.0 ? Color(UIColor.systemGreen) : Color(UIColor.systemBlue))
                                        
                                        Spacer()
                                        
                                        // 目标类型标签
                                        Text(goal.goalType.rawValue)
                                            .font(.system(size: 10))
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
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(UIColor.systemBlue))
                                    
                                    Text("查看更多")
                                        .font(.system(size: 14, weight: .medium))
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 成就展示区域
    private var achievementSection: some View {
        Button(action: {
            showingAchievementDetail = true
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemYellow))
                    Text("成就")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                                                            
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.systemGray))
                }
                
                // 成就图标 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(achievements.prefix(5)) { achievement in
                            VStack(alignment: .leading, spacing: 10) {
                                // 成就名称和图标
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color(UIColor.systemYellow).opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Text(achievement.emoji)
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(UIColor.systemYellow))
                                    }
                                    Text(achievement.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .lineLimit(1)
                                        .foregroundColor(Color(UIColor.label))
                                }
                                // 完成状态
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        if achievement.isCompleted {
                                            Text("已完成")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color(UIColor.systemGreen))
                                        } else {
                                            Text("未完成")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color(UIColor.systemYellow))
                                        }
                                        Spacer()
                                        // 成就类型标签
                                        Text(achievement.category)
                                            .font(.system(size: 10))
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingAchievementDetail = true
                            }
                        }
                        
                        // 查看更多按钮
                        if achievements.count > 3 {
                            Button(action: {
                                showingAchievementDetail = true
                            }) {
                                VStack(spacing: 10) {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(UIColor.systemYellow))
                                    
                                    Text("查看更多")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(UIColor.systemYellow))
                                }
                                .frame(width: 100, height: 80)
                                .padding(16)
                                .background(Color(UIColor.systemYellow).opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
                .frame(height: 56) // 增加高度以适应卡片

            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAchievementDetail) {
            NavigationStack {
                AchievementDetailView()
            }
            .presentationDetents([.height(400), .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var achievementCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemYellow))
                Text("成就")
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
                    ForEach(achievements.prefix(5)) { achievement in
                        VStack(spacing: 4) {
                            Text(achievement.emoji)
                                .font(.title2)
                                .frame(width: 42, height: 42)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                            
                            // 添加简短标签
                            Text(achievement.name)
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .lineLimit(1)
                        }
                        .frame(width: 60)
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
        Button(action: {
            showingImprovementDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemOrange))
                    Text("待改进")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    HStack(spacing: 4) {                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemGray))
                    }
                }
                
                // 待改进图标 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<improvements.count, id: \.self) { index in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.systemOrange).opacity(0.1))
                                        .frame(width: 56, height: 56)
                                    
                                    Text(improvements[index])
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(UIColor.systemOrange))
                                }
                                
                                // 添加简短标签
                                Text(improvementLabels[index])
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .lineLimit(1)
                                    .frame(width: 70)
                                    .multilineTextAlignment(.center)
                                
                                // 进度指示
                                if index % 2 == 0 { // 假设部分项目需要优先处理
                                    Text("优先")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(UIColor.systemOrange))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(UIColor.systemOrange).opacity(0.1))
                                        .cornerRadius(6)
                                } else {
                                    Text("一般")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(UIColor.systemGray5))
                                        .cornerRadius(6)
                                }
                            }
                            .frame(width: 70)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .frame(height: 100) // 增加高度以适应标签
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingImprovementDetail) {
            NavigationStack {
                ImprovementDetailView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .modelContainer(for: Item.self, inMemory: true)
    }
}
