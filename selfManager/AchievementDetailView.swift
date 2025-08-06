//
//  AchievementDetailView.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import SwiftUI
import SwiftData

struct AchievementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 成就分类
    private let categories = ["个人成长", "健康生活", "学习进步", "工作成就", "社交关系"]
    
    // 成就列表
    @State private var achievements = [
        Achievement(emoji: "🏆", name: "早起达人", description: "连续7天早上6点起床", category: "健康生活", isCompleted: true, completionDate: Date().addingTimeInterval(-86400 * 15), progress: 1.0),
        Achievement(emoji: "🥇", name: "阅读先锋", description: "累计阅读时间超过100小时", category: "学习进步", isCompleted: false, progress: 0.75),
        Achievement(emoji: "🥈", name: "运动健将", description: "单周运动时间超过10小时", category: "健康生活", isCompleted: true, completionDate: Date().addingTimeInterval(-86400 * 5), progress: 1.0),
        Achievement(emoji: "🥉", name: "社交达人", description: "建立10个有效社交关系", category: "社交关系", isCompleted: false, progress: 0.6),
        Achievement(emoji: "🎖️", name: "工作能手", description: "连续完成30天工作计划", category: "工作成就", isCompleted: false, progress: 0.3),
        Achievement(emoji: "🌟", name: "自律王者", description: "连续打卡90天", category: "个人成长", isCompleted: false, progress: 0.2),
        Achievement(emoji: "📚", name: "知识探索者", description: "完成5本书的阅读", category: "学习进步", isCompleted: true, completionDate: Date().addingTimeInterval(-86400 * 30), progress: 1.0),
        Achievement(emoji: "💪", name: "健身达人", description: "完成100次俯卧撑挑战", category: "健康生活", isCompleted: false, progress: 0.45)
    ]
    
    // 选中的分类
    @State private var selectedCategory: String? = nil
    
    // 显示模式
    @State private var showMode: ShowMode = .all
    
    // 编辑状态
    @State private var isEditing = false
    @State private var showingAddSheet = false
    @State private var newAchievement = Achievement(emoji: "🏆", name: "", description: "", category: "个人成长", isCompleted: false, progress: 0.0)
    
    // 成就统计
    private var completedCount: Int {
        achievements.filter { $0.isCompleted }.count
    }
    
    private var totalCount: Int {
        achievements.count
    }
    
    private var completionRate: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
    }
    
    // 分类统计
    private func categoryCount(_ category: String) -> Int {
        achievements.filter { $0.category == category }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 成就统计卡片
                achievementStatsCard
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // 分类选择器
                categorySelector
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // 成就列表
                achievementList
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("成就中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showMode = .all }) {
                            Label("全部", systemImage: "list.bullet")
                        }
                        Button(action: { showMode = .completed }) {
                            Label("已完成", systemImage: "checkmark.circle")
                        }
                        Button(action: { showMode = .inProgress }) {
                            Label("进行中", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                    // 编辑按钮
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "完成" : "编辑")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isEditing ? Color(UIColor.systemBlue) : Color(UIColor.systemGray))
                    }
                    
                    // 添加按钮
                    Button(action: {
                        newAchievement = Achievement(emoji: "🏆", name: "", description: "", category: "个人成长", isCompleted: false, progress: 0.0)
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("基本信息")) {
                            TextField("成就名称", text: $newAchievement.name)
                            TextField("成就描述", text: $newAchievement.description)
                            TextField("表情图标", text: $newAchievement.emoji)
                        }
                        
                        Section(header: Text("分类")) {
                            Picker("选择分类", selection: $newAchievement.category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                        }
                        
                        Section(header: Text("进度")) {
                            Slider(value: $newAchievement.progress, in: 0...1, step: 0.05)
                            Text("当前进度: \(Int(newAchievement.progress * 100))%")
                        }
                    }
                    .navigationTitle("添加成就")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("取消") {
                                showingAddSheet = false
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("保存") {
                                achievements.append(newAchievement)
                                showingAddSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // 成就统计卡片 - 简化版本
    private var achievementStatsCard: some View {
        HStack(spacing: 20) {
            // 已完成成就
            VStack(spacing: 6) {
                Text("\(completedCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.systemGreen))
                
                Text("已完成")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGreen).opacity(0.1))
            .cornerRadius(12)
            
            // 进行中成就
            VStack(spacing: 6) {
                Text("\(totalCount - completedCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.systemBlue))
                
                Text("进行中")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBlue).opacity(0.1))
            .cornerRadius(12)
            
            // 总成就
            VStack(spacing: 6) {
                Text("\(totalCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.systemOrange))
                
                Text("总成就")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemOrange).opacity(0.1))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // 分类选择器
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部分类按钮
                categoryButton(nil)
                
                // 各个分类按钮
                ForEach(categories, id: \.self) { category in
                    categoryButton(category)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
    
    // 分类按钮
    private func categoryButton(_ category: String?) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            Text(category ?? "全部")
                .font(.subheadline)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedCategory == category ? Color(UIColor.systemBlue) : Color(UIColor.systemGray6))
                .foregroundColor(selectedCategory == category ? .white : Color(UIColor.label))
                .cornerRadius(16)
        }
    }
    
    // 成就列表
    private var filteredAchievements: [Achievement] {
        var result = achievements
        
        // 按分类筛选
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // 按完成状态筛选
        switch showMode {
        case .completed:
            result = result.filter { $0.isCompleted }
        case .inProgress:
            result = result.filter { !$0.isCompleted }
        case .all:
            break
        }
        
        return result
    }
    
    // 成就列表
    private var achievementList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("成就列表")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    newAchievement = Achievement(emoji: "🏆", name: "", description: "", category: "个人成长", isCompleted: false, progress: 0.0)
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(UIColor.systemBlue))
                }
            }
            .padding(.horizontal, 16)
            
            if filteredAchievements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(Color(UIColor.systemGray3))
                    
                    Text("暂无成就")
                        .font(.headline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Button(action: {
                        newAchievement = Achievement(emoji: "🏆", name: "", description: "", category: "个人成长", isCompleted: false, progress: 0.0)
                        showingAddSheet = true
                    }) {
                        Text("添加成就")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.systemBlue))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                // 成就列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAchievements.indices, id: \.self) { index in
                            achievementRow(filteredAchievements[index])
                                .contextMenu {
                                    Button(action: {
                                        newAchievement = filteredAchievements[index]
                                        showingAddSheet = true
                                    }) {
                                        Label("编辑", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        withAnimation {
                                            let achievementToRemove = filteredAchievements[index]
                                            if let originalIndex = achievements.firstIndex(where: { $0.name == achievementToRemove.name }) {
                                                achievements.remove(at: originalIndex)
                                            }
                                        }
                                    }) {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // 成就行视图
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            // Emoji图标
            Text(achievement.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(achievement.isCompleted ? Color(UIColor.systemBlue).opacity(0.1) : Color(UIColor.systemGray6))
                .clipShape(Circle())
            
            // 成就信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if achievement.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
                
                if achievement.isCompleted {
                    HStack {
                        Text("已完成")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.systemGreen))
                        
                        if let date = achievement.completionDate {
                            Text(dateFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                } else {
                    // 进度条
                    HStack {
                        ProgressView(value: achievement.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("\(Int(achievement.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            
            if isEditing {
                Button(action: {
                    if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
                        achievements.remove(at: index)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                // 查看成就详情
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// 成就模型
struct Achievement: Identifiable {
    var id = UUID()
    var emoji: String
    var name: String
    var description: String
    var category: String
    var isCompleted: Bool
    var completionDate: Date?
    var progress: Double // 0.0 - 1.0
}

// 显示模式枚举
enum ShowMode {
    case all
    case completed
    case inProgress
}

#Preview {
    AchievementDetailView()
}