//
//  AmazingLifeApp.swift
//  AmazingLife
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
struct AmazingLifeApp: App {
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
    // 三段式外观设置：light / dark / system
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    // 监听系统颜色方案以便在“跟随系统”时实时同步
    @Environment(\.colorScheme) private var colorScheme
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
            // 使用当前版本模型并启用迁移计划
            let schema = Schema([
                Goal.self,
                GoalTask.self,
                Item.self,
                Record.self,
                Contact.self,
                User.self,
                Asset.self,
                Tag.self,
                TagCategory.self
            ])
            let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
            let storeURL = supportDir.appendingPathComponent("default_nocloud.store")
            let configuration = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
            do {
                self.sharedModelContainer = try ModelContainer(for: schema, configurations: configuration)
            } catch {
                let fallbackURL = supportDir.appendingPathComponent("default_nocloud_fallback.store")
                let fallbackConfig = ModelConfiguration(url: fallbackURL, cloudKitDatabase: .none)
                self.sharedModelContainer = try ModelContainer(for: schema, configurations: fallbackConfig)
            }
            
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

    // 一次性规范化旧数据的子任务状态：将已完成的任务标记为done
    private func normalizeTaskStatus(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<GoalTask>()
        if let tasks = try? modelContext.fetch(descriptor) {
            var changed = false
            for task in tasks {
                // 如果旧数据中 isCompleted 为 true，但状态尚未同步，则设置为 done
                if task.isCompleted && task.status != .done {
                    task.status = .done
                    changed = true
                }
            }
            if changed {
                try? modelContext.save()
            }
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
                                Text("home".localized)
                            }
                            .tag(0)
                        
                        GoalView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "target")
                                Text("goals".localized)
                            }
                            .tag(1)
                        
                        RecordView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "newspaper.fill")
                                Text("records".localized)
                            }
                            .tag(2)
                        
                        ContactView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "network")
                                Text("contacts".localized)
                            }
                            .tag(3)
                    }
                            // 应用全局系统字体修饰符，使文本默认使用系统动态字体
                            .useGlobalSystemTypography()
                    .onAppear {
                        // 启动垃圾清理服务
                TrashCleanupService.shared.startPeriodicCleanup(modelContext: container.mainContext)
                initializeSampleData(modelContext: container.mainContext)
                normalizeTaskStatus(modelContext: container.mainContext)
                WidgetSharedDataManager.shared.writeSummary(modelContext: container.mainContext)
                Task {
                    await CloudKitSyncManager.shared.checkAccountStatus()
                    if CloudKitSyncManager.shared.accountAvailable {
                        await CloudKitSyncManager.shared.startSync(modelContext: container.mainContext)
                        WidgetSharedDataManager.shared.writeSummary(modelContext: container.mainContext)
                    }
                }
            }
                            
                            // 侧边栏覆盖层（提升层级，覆盖底部导航栏）
                            SidebarView(isPresented: $sidebarManager.isPresented, selectedTab: $selectedTab)
                                .zIndex(1000)
                        }
                        .modelContainer(container)
                        .enableSwipeBackGesture()
                        // 外观模式：当为 system 时不强制颜色方案，交由系统管理
                        .preferredColorScheme(
                            appearanceMode == "system" ? nil : (appearanceMode == "dark" ? .dark : .light)
                        )
                        // 系统可读性粗细（无障碍“粗体文本”）自动响应
                        .applySystemLegibilityWeight()
                        .environmentObject(localizationManager)
                        .id(refreshApp) // 强制整个应用在语言变化时刷新
                        .onReceive(localizationManager.$currentLanguage) { _ in
                            // 强制整个应用刷新
                            refreshApp = UUID()
                        }
                        // 当选择“跟随系统”时，实时同步系统的深色/浅色
                        .onAppear {
                            if appearanceMode == "system" {
                                isDarkMode = (colorScheme == .dark)
                            }
                        }
                        .onChange(of: colorScheme) { newScheme in
                            if appearanceMode == "system" {
                                isDarkMode = (newScheme == .dark)
                            }
                        }
                        // 当用户切换三段式外观选项时，保持 isDarkMode 与之同步
                        .onChange(of: appearanceMode) { newMode in
                            if newMode == "system" {
                                isDarkMode = (colorScheme == .dark)
                            } else {
                                isDarkMode = (newMode == "dark")
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            WidgetSharedDataManager.shared.writeSummary(modelContext: container.mainContext)
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
