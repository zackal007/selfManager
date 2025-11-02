//
//  selfManagerApp.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import SwiftData
// 确保ModelMigrations和ModelVersion可用
import Foundation
import UIKit
// 导入语言本地化管理器
import Combine

// 设置UITabBar的外观
class AppAppearance {
    static func setupAppearance() {
        // 设置TabBar选中项的颜色为蓝色
        UITabBar.appearance().tintColor = UIColor.systemBlue

        // 统一 TabBar 外观以与首页一致（使用系统默认的半透明模糊背景）
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground() // 默认模糊半透明样式
        // 保持系统默认背景颜色与模糊效果，不强制设定为不透明
        tabAppearance.backgroundColor = nil
        tabAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.15)

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }
        tabBar.isTranslucent = true

        // 设置其他UI元素的颜色
        UIButton.appearance().tintColor = UIColor.systemBlue

        // 统一导航栏外观，避免透明与颜色不一致
        let navAppearance = UINavigationBarAppearance()
        // 使用不透明背景，防止滚动到顶部时出现透明效果
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        // 统一标题文字颜色
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        // 细化阴影线条，弱化分割线存在感（可按需调整或置为nil）
        navAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.2)

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navAppearance
        navigationBar.scrollEdgeAppearance = navAppearance
        navigationBar.compactAppearance = navAppearance
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIColor.systemBlue
    }
}

@main
struct selfManagerApp: App {
    // 使用@State来管理ModelContainer，确保在主线程上创建和访问
    @State private var sharedModelContainer: ModelContainer?
    // 添加状态变量来跟踪当前选中的标签页
    @State private var selectedTab = 0
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var sidebarManager = SidebarManager.shared
    @State private var loadingError: Error? = nil
    // 添加状态变量来控制欢迎页面的显示
    @State private var isShowingWelcome = true
    @State private var isLoading = true
    // 添加深色模式支持
    @AppStorage("isDarkMode") private var isDarkMode = false
    // 添加语言设置支持
    @StateObject private var localizationManager = LocalizationManager.shared
    // 用于强制刷新整个应用的ID
    @State private var refreshApp = UUID()
    
    /// 收起键盘的方法
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    init() {
        // 初始化时不创建ModelContainer，而是在onAppear中创建
        // 这样可以确保在主线程上创建ModelContainer
        
        // 设置应用外观
        AppAppearance.setupAppearance()
    }
    
    // 初始化ModelContainer的方法
    private func initializeModelContainer() {
        // 设置加载状态
        isLoading = true
        // 重置错误状态
        loadingError = nil
        
        // 在主线程上创建ModelContainer
        do {
            // 使用简化的方式创建模型容器，只包含当前版本的模型
            let schema = Schema([
                ModelSchemaV4.Goal.self,
                ModelSchemaV4.GoalTask.self,
                Item.self,
                Record.self,
                Contact.self,
                User.self,
                Asset.self,
                Tag.self,
                TagCategory.self
            ])
            // 不使用迁移计划，避免未知模型版本的问题
            self.sharedModelContainer = try ModelContainer(for: schema)
            
            // 优化动画效果，使其更丝滑
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 保持ModelContainer初始化后的延迟
                withAnimation(.easeInOut(duration: 0.3)) { // isLoading动画时长增加到0.3s
                    isLoading = false
                }
                
                // 缩短二次延迟，让isShowingWelcome动画紧随其后
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.4)) { // isShowingWelcome动画时长增加到0.4s，使用easeOut
                        isShowingWelcome = false
                    }
                }
            }
        } catch {
            // 保存错误以便显示给用户
            loadingError = error
            isLoading = false
            print("Could not create ModelContainer: \(error)")
        }
    }
    
    // 初始化示例数据
    private func initializeSampleData(modelContext: ModelContext) {
        // 强制重新创建示例数据以解决标签显示问题
        let tagDescriptor = FetchDescriptor<Tag>()
        let userDescriptor = FetchDescriptor<User>()
        
        do {
            let existingTags = try modelContext.fetch(tagDescriptor)
            let existingUsers = try modelContext.fetch(userDescriptor)
            
            // 如果没有用户数据，创建默认用户
            if existingUsers.isEmpty {
                let defaultUser = User(
                    name: "张三",
                    avatar: "👤",
                    tags: [],
                    userDescription: "热爱生活，追求自我提升的普通人"
                )
                modelContext.insert(defaultUser)
            }
            
            // 确保系统内置标签存在
            BuiltInTags.ensureExists(modelContext: modelContext)
            
            // 保存更改
            try modelContext.save()
            print("示例数据初始化完成")
            
        } catch {
            print("初始化示例数据失败: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主应用内容
                Group {
                    if let container = sharedModelContainer {
                        ZStack {
            // 顶栏/入口导航：应用主 TabBar（修改标签或顺序从这里入手）
            TabView(selection: $selectedTab) {
                        HomeView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "person.fill")
                                Text("我")
                            }
                            .tag(0)
                            .onTapGesture {
                                dismissKeyboard()
                                let shouldPopToRoot = navigationManager.handleTabTap(tabIndex: 0, currentTab: selectedTab)
                                if !shouldPopToRoot {
                                    selectedTab = 0
                                }
                            }
                        
                        GoalView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "target")
                                Text("目标")
                            }
                            .tag(1)
                            .onTapGesture {
                                dismissKeyboard()
                                let shouldPopToRoot = navigationManager.handleTabTap(tabIndex: 1, currentTab: selectedTab)
                                if !shouldPopToRoot {
                                    selectedTab = 1
                                }
                            }
                        
                        RecordView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "newspaper.fill")
                                Text("记录")
                            }
                            .tag(2)
                            .onTapGesture {
                                dismissKeyboard()
                                let shouldPopToRoot = navigationManager.handleTabTap(tabIndex: 2, currentTab: selectedTab)
                                if !shouldPopToRoot {
                                    selectedTab = 2
                                }
                            }
                        
                        ContactView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "network")
                                Text("人脉")
                            }
                            .tag(3)
                            .onTapGesture {
                                dismissKeyboard()
                                let shouldPopToRoot = navigationManager.handleTabTap(tabIndex: 3, currentTab: selectedTab)
                                if !shouldPopToRoot {
                                    selectedTab = 3
                                }
                            }
                    }
                            .onAppear {
                                // 启动垃圾清理服务
                TrashCleanupService.shared.startPeriodicCleanup(modelContext: container.mainContext)
                initializeSampleData(modelContext: container.mainContext)
            }
                            
                            // 侧边栏覆盖层（提升层级，覆盖底部导航栏）
                            SidebarView(isPresented: $sidebarManager.isPresented, selectedTab: $selectedTab)
                                .zIndex(1000)
                        }
                        .modelContainer(container)
                        .enableSwipeBackGesture()
                        .preferredColorScheme(isDarkMode ? .dark : .light) // 应用深色模式设置
                        .environmentObject(localizationManager)
                        .id(refreshApp) // 强制整个应用在语言变化时刷新
                        .onReceive(localizationManager.$currentLanguage) { _ in
                            // 强制整个应用刷新
                            refreshApp = UUID()
                        }
                    } else {
                        // 空视图，当欢迎页面显示时作为占位符
                        Color.clear
                            .onAppear {
                                if !isShowingWelcome {
                                    initializeModelContainer()
                                }
                            }
                    }
                }
                
                // 欢迎页面，根据状态显示或隐藏
                if isShowingWelcome {
                    WelcomeView(
                        loadingError: loadingError,
                        retryAction: {
                            initializeModelContainer()
                        },
                        isLoading: isLoading
                    )
                    .transition(.opacity)
                    .zIndex(1) // 确保欢迎页面在最上层
                    .onAppear {
                        if sharedModelContainer == nil {
                            initializeModelContainer()
                        }
                    }
                }
            }
        }
    }
}
