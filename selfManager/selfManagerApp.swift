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
    let sharedModelContainer: ModelContainer
    // 添加状态变量来跟踪当前选中的标签页
    @State private var selectedTab = 0

    init() {
        do {
            // 配置模型迁移计划
            let schema = Schema(versionedSchema: ModelSchemaV2.self)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            // 创建包含Goal、GoalTask、Record和Contact模型的容器
            sharedModelContainer = try ModelContainer(for: Goal.self, GoalTask.self, Item.self, Record.self, Contact.self, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
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
        }
        .modelContainer(sharedModelContainer)
    }
}
