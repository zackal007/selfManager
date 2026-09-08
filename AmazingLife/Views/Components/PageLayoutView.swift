//
//  PageLayoutView.swift
//  AmazingLife
//
//  通用的页面布局模板 - 基于 GoalView 的布局抽象
//

import SwiftUI
import UIKit

// MARK: - 页面 Header 配置
struct PageHeaderConfig {
    let title: String
    var menuContent: (() -> AnyView)? = nil  // 右侧更多菜单内容
}

// MARK: - Tab 页签配置
struct PageTabItem: Identifiable {
    let id: Int
    let title: String
    let icon: String? = nil
}

// MARK: - FAB 悬浮按钮配置
struct FABConfig {
    var isEnabled: Bool = true
    var isHidden: Bool = false  // 用于详情页等不需要的场景
    var action: () -> Void = {}
    var iconName: String = "plus"
}

// MARK: - 内容视图模式
enum PageViewMode {
    case gallery
    case list
}

// MARK: - 通用页面布局视图
struct PageLayoutView<GalleryContent: View, ListContent: View>: View {
    // MARK: - 环境
    @Environment(\.modelContext) private var modelContext

    // MARK: - Header 配置
    let headerConfig: PageHeaderConfig

    // MARK: - Tab 页签
    let tabs: [PageTabItem]
    @Binding var selectedTabIndex: Int

    // MARK: - 视图模式
    @Binding var viewMode: PageViewMode

    // MARK: - FAB 配置
    let fabConfig: FABConfig

    // MARK: - 导航路由
    let navigationPath: Binding<NavigationPath>
    let onNavigate: (AppRoute) -> Void

    // MARK: - 内容构建器
    @ViewBuilder let galleryContentBuilder: (Int) -> GalleryContent
    @ViewBuilder let listContentBuilder: (Int) -> ListContent

    // MARK: - 内部状态
    @State private var fabPressed = false

    // MARK: - 导航管理器
    @StateObject private var navigationManager = NavigationManager.shared

    var body: some View {
        GeometryReader { outerGeometry in
            let topSafeArea = outerGeometry.safeAreaInsets.top

            ZStack(alignment: .top) {
                // MARK: 内容区域
                NavigationStack(path: navigationPath) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // 透明占位 - 固定高度（Tab页签区域）
                            Color.clear
                                .frame(height: 50)

                            // 内容
                            Group {
                                switch viewMode {
                                case .gallery:
                                    galleryContentBuilder(selectedTabIndex)
                                case .list:
                                    listContentBuilder(selectedTabIndex)
                                }
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationBarHidden(true)
                    .navigationDestination(for: AppRoute.self) { route in
                        Color.clear
                            .onAppear { onNavigate(route) }
                    }
                }

                // MARK: Header 悬浮覆盖层
                headerView(topPadding: topSafeArea)

                // MARK: FAB 悬浮按钮
                if !fabConfig.isHidden {
                    fabButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header 视图
    private func headerView(topPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 第一行：标题 + 菜单
            HStack(alignment: .center) {
                Text(headerConfig.title)
                    .font(AppFont.navTitle())
                    .foregroundColor(Color(UIColor.label))
                    .padding(.leading, 8)

                Spacer()

                // 菜单（可选）
                if let menuContent = headerConfig.menuContent {
                    menuContent()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)

            // 第二行：Tab 页签
            HStack(spacing: 10) {
                ForEach(tabs) { tab in
                    PageTabChip(
                        title: tab.title,
                        isSelected: selectedTabIndex == tab.id
                    ) {
                        selectedTabIndex = tab.id
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 7)
        }
        .padding(.top, topPadding)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .top)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
        .zIndex(10)
    }

    // MARK: - FAB 悬浮按钮
    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    fabConfig.action()
                }) {
                    Image(systemName: fabConfig.iconName)
                        .font(.system(size: 14.4, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 39.6, height: 39.6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.9),
                                    Color.blue
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .scaleEffect(fabPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: fabPressed)
                }
                .buttonStyle(PlainButtonStyle())
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    fabPressed = pressing
                }, perform: {})
            }
        }
    }
}

// MARK: - 页签 Chip 组件
struct PageTabChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? AppFont.subtextMedium() : AppFont.subtext())
                .foregroundColor(isSelected ? Color(UIColor.systemBlue) : Color(UIColor.secondaryLabel))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected
                              ? Color(UIColor.systemBlue).opacity(0.15)
                              : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
