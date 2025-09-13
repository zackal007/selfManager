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

// 设置UITabBar的外观
class AppAppearance {
    static func setupAppearance() {
        // 设置TabBar选中项的颜色为蓝色
        UITabBar.appearance().tintColor = UIColor.systemBlue
        
        // 设置其他UI元素的颜色
        UIButton.appearance().tintColor = UIColor.systemBlue
    }
}

@main
struct selfManagerApp: App {
    // 使用@State来管理ModelContainer，确保在主线程上创建和访问
    @State private var sharedModelContainer: ModelContainer?
    // 添加状态变量来跟踪当前选中的标签页
    @State private var selectedTab = 0
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var loadingError: Error? = nil
    // 添加状态变量来控制欢迎页面的显示
    @State private var isShowingWelcome = true
    @State private var isLoading = true
    
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

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主应用内容
                Group {
                    if let container = sharedModelContainer {
                        TabView(selection: $selectedTab) {
                            HomeView(selectedTab: $selectedTab)
                                .tabItem {
                                    Image(systemName: "house.fill")
                                    Text("首页")
                                }
                                .tag(0)
                                .onTapGesture {
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
                                    let shouldPopToRoot = navigationManager.handleTabTap(tabIndex: 2, currentTab: selectedTab)
                                    if !shouldPopToRoot {
                                        selectedTab = 2
                                    }
                                }
                            
                            ContactView(selectedTab: $selectedTab)
                                .tabItem {
                                    Image(systemName: "person.3.fill")
                                    Text("人脉")
                                }
                                .tag(3)
                                .onTapGesture {
                                    let shouldPopToRoot = navigationManager.handleTabTap(tabIndex: 3, currentTab: selectedTab)
                                    if !shouldPopToRoot {
                                        selectedTab = 3
                                    }
                                }
                        }
                        .modelContainer(container)
                        .enableSwipeBackGesture()
                        .onAppear {
                            // 启动回收站清理服务
                            TrashCleanupService.shared.startPeriodicCleanup(modelContext: container.mainContext)
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
