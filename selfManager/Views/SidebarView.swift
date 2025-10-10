//
//  SidebarView.swift
//  selfManager
//
//  Created by Assistant on 2025/1/17.
//

import SwiftUI
import SwiftData

// 侧边栏菜单项数据模型
struct SidebarMenuItem {
    let id = UUID()
    let title: String
    let icon: String
    let badge: String?
    let action: () -> Void
    
    init(title: String, icon: String, badge: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.badge = badge
        self.action = action
    }
}

// 侧边栏视图
struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var contacts: [Contact]
    @Query private var users: [User]
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
    @Binding var isPresented: Bool
    @Binding var selectedTab: Int
    @State private var dragOffset: CGFloat = 0
    @State private var showingTagsView = false
    @State private var showingSettingsView = false
    @StateObject private var navigationManager = NavigationManager.shared
    
    // 侧边栏宽度
    private let sidebarWidth: CGFloat = 320
    
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
    
    // 计算使用标签的项目数量
    private func countItemsWithTag(_ tag: String) -> Int {
        var count = 0
        
        // 计算目标中的标签使用
        for goal in goals where !goal.isDeleted {
            if goal.tags.contains(tag) {
                count += 1
            }
        }
        
        // 计算联系人中的标签使用
        for contact in contacts {
            if contact.tags.contains(tag) {
                count += 1
            }
        }
        
        // 计算用户中的标签使用
        for user in users {
            if user.tags.contains(tag) {
                count += 1
            }
        }
        
        return count
    }
    
    // 主要导航菜单项
    private var mainMenuItems: [SidebarMenuItem] {
        [
            SidebarMenuItem(title: "首页", icon: "house.fill") {
                selectedTab = 0
                closeSidebar()
            },
            SidebarMenuItem(title: "目标", icon: "target", badge: "\(goals.filter { !$0.isDeleted }.count)") {
                selectedTab = 1
                closeSidebar()
            },
            SidebarMenuItem(title: "记录", icon: "newspaper.fill") {
                selectedTab = 2
                closeSidebar()
            },
            SidebarMenuItem(title: "人脉", icon: "person.3.fill", badge: "\(contacts.count)") {
                selectedTab = 3
                closeSidebar()
            }
        ]
    }
    
    // 工具菜单项
    private var toolMenuItems: [SidebarMenuItem] {
        [
            SidebarMenuItem(title: "标签管理", icon: "tag.fill", badge: "\(getAllTags().count)") {
                // 将“标签管理”推入当前选中标签页的导航栈
                switch selectedTab {
                case 0:
                    navigationManager.homeNavigationPath.append(AppRoute.tags)
                case 1:
                    navigationManager.goalNavigationPath.append(AppRoute.tags)
                case 2:
                    navigationManager.recordNavigationPath.append(AppRoute.tags)
                case 3:
                    navigationManager.contactNavigationPath.append(AppRoute.tags)
                default:
                    navigationManager.homeNavigationPath.append(AppRoute.tags)
                }
                closeSidebar()
            },
            SidebarMenuItem(title: "帮助与反馈", icon: "questionmark.circle") {
                // 这里可以添加帮助页面的导航逻辑
                closeSidebar()
            }
        ]
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeSidebar()
                    }
                    .transition(.opacity)
            }
            
            // 侧边栏内容
            HStack(spacing: 0) {
                // 侧边栏主体
                VStack(spacing: 0) {
                    // 顶部用户信息区域
                    HStack(spacing: 12) {
                        // 用户头像
                        if let user = users.first, !user.avatar.isEmpty, let uiImage = ImageUtility.loadImageFromAppDirectory(fileName: user.avatar) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
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
                                .frame(width: 50, height: 50)
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
                        
                        // 用户信息
                        VStack(alignment: .leading, spacing: 2) {
                            Text(users.first?.name ?? "尚未登录")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(UIColor.label))
                            
                            HStack(spacing: 4) {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color(UIColor.systemBlue))
                                    )
                            }
                        }
                        
                        Spacer()
                        
                        // 设置按钮
                        Button(action: {
                            // 将“设置”推入当前选中标签页的导航栈
                            switch selectedTab {
                            case 0:
                                navigationManager.homeNavigationPath.append(AppRoute.settings)
                            case 1:
                                navigationManager.goalNavigationPath.append(AppRoute.settings)
                            case 2:
                                navigationManager.recordNavigationPath.append(AppRoute.settings)
                            case 3:
                                navigationManager.contactNavigationPath.append(AppRoute.settings)
                            default:
                                navigationManager.homeNavigationPath.append(AppRoute.settings)
                            }
                            closeSidebar()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                         VStack(spacing: 16) {
                             // 记录热力图卡片
                             HeatmapView()
                             
                             // 所有标签卡片
                             AllTagsCardView(showingTagsView: $showingTagsView)
                         }
                         .padding(.horizontal, 16)
                         .padding(.bottom, 16)
                     }
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .frame(width: sidebarWidth)
                .background(
                    Color(UIColor.systemGroupedBackground)
                        .ignoresSafeArea(.all)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 2, y: 0)
                )
                .offset(x: isPresented ? dragOffset : -sidebarWidth)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 只允许向左拖拽关闭
                            if value.translation.width < 0 {
                                dragOffset = max(value.translation.width, -sidebarWidth)
                            }
                        }
                        .onEnded { value in
                            // 如果拖拽距离超过一定阈值，则关闭侧边栏
                            if value.translation.width < -100 || value.predictedEndTranslation.width < -200 {
                                closeSidebar()
                            } else {
                                // 否则回弹到原位置
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                
                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        .onAppear {
            dragOffset = 0
        }
        // 监听“查看全部标签”触发，切换到首页并推入标签管理页
        .onChange(of: showingTagsView) { newValue in
            if newValue {
                // 将“标签管理”推入当前选中标签页的导航栈
                switch selectedTab {
                case 0:
                    navigationManager.homeNavigationPath.append(AppRoute.tags)
                case 1:
                    navigationManager.goalNavigationPath.append(AppRoute.tags)
                case 2:
                    navigationManager.recordNavigationPath.append(AppRoute.tags)
                case 3:
                    navigationManager.contactNavigationPath.append(AppRoute.tags)
                default:
                    navigationManager.homeNavigationPath.append(AppRoute.tags)
                }
                // 关闭侧边栏并复位状态
                closeSidebar()
                showingTagsView = false
            }
        }
        // 已改为 push 导航，不再使用弹窗展示
    }
    
    // 关闭侧边栏
    private func closeSidebar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
            dragOffset = 0
        }
    }
    
    // 判断菜单项是否被选中
    private func isMenuItemSelected(_ item: SidebarMenuItem) -> Bool {
        switch item.title {
        case "首页":
            return selectedTab == 0
        case "目标":
            return selectedTab == 1
        case "记录":
            return selectedTab == 2
        case "人脉":
            return selectedTab == 3
        default:
            return false
        }
    }
}

// 卡片式菜单项视图
struct SidebarCardMenuItemView: View {
    let item: SidebarMenuItem
    let isSelected: Bool
    @State private var isPressed = false
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
                    .frame(width: 20, height: 20)
                
                // 标题
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
                
                Spacer()
                
                // 徽章
                if let badge = item.badge, !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? Color(UIColor.systemBlue) : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white : Color(UIColor.systemBlue))
                        )
                }
                
                // 选中指示器
                if isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(UIColor.systemBlue) : (isPressed ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground)))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// 侧边栏管理器
class SidebarManager: ObservableObject {
    @Published var isPresented = false
    
    static let shared = SidebarManager()
    
    private init() {}
    
    func showSidebar() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = true
        }
    }
    
    func hideSidebar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
    
    func toggleSidebar() {
        if isPresented {
            hideSidebar()
        } else {
            showSidebar()
        }
    }
}

// 侧边栏触发按钮
struct SidebarTriggerButton: View {
    @ObservedObject private var sidebarManager = SidebarManager.shared
    
    var body: some View {
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
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
        
        SidebarView(isPresented: .constant(true), selectedTab: .constant(0))
    }
}