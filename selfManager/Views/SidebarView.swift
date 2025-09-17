//
//  SidebarView.swift
//  selfManager
//
//  Created by Assistant on 2025/1/17.
//

import SwiftUI

// 侧边栏菜单项数据模型
struct SidebarMenuItem {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

// 侧边栏视图
struct SidebarView: View {
    @Binding var isPresented: Bool
    @Binding var selectedTab: Int
    @State private var dragOffset: CGFloat = 0
    
    // 侧边栏宽度
    private let sidebarWidth: CGFloat = 280
    
    // 菜单项
    private var menuItems: [SidebarMenuItem] {
        [
            SidebarMenuItem(title: "首页", icon: "house.fill") {
                selectedTab = 0
                closeSidebar()
            },
            SidebarMenuItem(title: "目标", icon: "target") {
                selectedTab = 1
                closeSidebar()
            },
            SidebarMenuItem(title: "记录", icon: "newspaper.fill") {
                selectedTab = 2
                closeSidebar()
            },
            SidebarMenuItem(title: "人脉", icon: "person.3.fill") {
                selectedTab = 3
                closeSidebar()
            },
            SidebarMenuItem(title: "设置", icon: "gearshape") {
                // 这里可以添加设置页面的导航逻辑
                closeSidebar()
            },
            SidebarMenuItem(title: "帮助", icon: "questionmark.circle") {
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
                    VStack(spacing: 16) {
                        // 用户头像
                        Circle()
                            .fill(Color(UIColor.systemBlue))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )
                        
                        // 用户名
                        VStack(spacing: 4) {
                            Text("用户名")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(UIColor.label))
                            
                            Text("个人管理助手")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 30)
                    
                    // 菜单项列表
                    VStack(spacing: 8) {
                        ForEach(menuItems, id: \.id) { item in
                            SidebarMenuItemView(
                                item: item,
                                isSelected: isMenuItemSelected(item)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 底部版本信息
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        Text("版本 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .padding(.bottom, 30)
                    }
                }
                .frame(width: sidebarWidth)
                .background(
                    Color(UIColor.systemBackground)
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

// 侧边栏菜单项视图
struct SidebarMenuItemView: View {
    let item: SidebarMenuItem
    let isSelected: Bool
    @State private var isPressed = false
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
                    .frame(width: 24, height: 24)
                
                // 标题
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
                
                Spacer()
                
                // 选中指示器
                if isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(UIColor.systemBlue) : (isPressed ? Color(UIColor.systemGray5) : Color.clear))
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