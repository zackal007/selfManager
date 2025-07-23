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

@main
struct selfManagerApp: App {
    // 使用@State来管理ModelContainer，确保在主线程上创建和访问
    @State private var sharedModelContainer: ModelContainer?
    // 添加状态变量来跟踪当前选中的标签页
    @State private var selectedTab = 0
    @State private var loadingError: Error? = nil
    
    init() {
        // 初始化时不创建ModelContainer，而是在onAppear中创建
        // 这样可以确保在主线程上创建ModelContainer
    }
    
    // 初始化ModelContainer的方法
    private func initializeModelContainer() {
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
                Asset.self
            ])
            // 不使用迁移计划，避免未知模型版本的问题
            self.sharedModelContainer = try ModelContainer(for: schema)
        } catch {
            // 保存错误以便显示给用户
            loadingError = error
            print("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = sharedModelContainer {
                    TabView(selection: $selectedTab) {
                        HomeView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("首页")
                            }
                            .tag(0)
                        
                        GoalView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "target")
                                Text("目标")
                            }
                            .tag(1)
                        
                        RecordView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "newspaper.fill")
                                Text("记录")
                            }
                            .tag(2)
                        
                        ContactView(selectedTab: $selectedTab)
                            .tabItem {
                                Image(systemName: "person.3.fill")
                                Text("人脉")
                            }
                            .tag(3)
                    }
                    .modelContainer(container)
                    .onAppear {
                        // 启动回收站清理服务
                        TrashCleanupService.shared.startPeriodicCleanup(modelContext: container.mainContext)
                    }
                } else {
                    // 显示加载视图和错误处理
                    VStack {
                        if loadingError == nil {
                            ProgressView("正在加载数据...")
                                .padding()
                        } else {
                            // 显示错误信息
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                
                                Text("数据加载失败")
                                    .font(.headline)
                                
                                Text(loadingError?.localizedDescription ?? "未知错误")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        
                        // 添加重试按钮，提供用户反馈和交互
                        Button("重试") {
                            initializeModelContainer()
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                        .disabled(loadingError == nil) // 只有在出错时才启用重试按钮
                    }
                    .onAppear {
                        initializeModelContainer()
                    }
                }
            }
        }
    }
}
