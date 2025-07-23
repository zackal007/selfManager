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
    
    // 成就统计
    private var completedCount: Int {
        achievements.filter { $0.isCompleted }.count
    }
    
    private var totalCount: Int {
        achievements.count
    }
    
    private var completionRate: Double {
        Double(completedCount) / Double(totalCount)
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
            }
        }
    }
    
    // 成就统计卡片
    private var achievementStatsCard: some View {
        VStack(spacing: 16) {
            // 成就完成率
            VStack(spacing: 8) {
                Text("成就完成率")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(String(format: "%.0f", completionRate * 100))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.systemBlue))
                    
                    Text("%")
                        .font(.title2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.bottom, 8)
                }
            }
            
            // 进度条
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 8)
                    .foregroundColor(Color(UIColor.systemGray5))
                
                // 进度
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: CGFloat(completionRate) * UIScreen.main.bounds.width - 48, height: 8)
                    .foregroundColor(Color(UIColor.systemBlue))
            }
            
            // 成就数量
            HStack(spacing: 0) {
                // 已完成
                VStack(spacing: 6) {
                    Text("已完成")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text("\(completedCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 1, height: 36)
                
                // 总成就
                VStack(spacing: 6) {
                    Text("总成就")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text("\(totalCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 3, x: 0, y: 1)
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
    private var achievementList: some View {
        let filteredAchievements = achievements
            .filter { achievement in
                // 根据分类筛选
                (selectedCategory == nil || achievement.category == selectedCategory) &&
                // 根据显示模式筛选
                (showMode == .all ||
                 (showMode == .completed && achievement.isCompleted) ||
                 (showMode == .inProgress && !achievement.isCompleted))
            }
        
        return List {
            ForEach(filteredAchievements) { achievement in
                achievementRow(achievement: achievement)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // 成就行视图
    private func achievementRow(achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            // Emoji图标
            Text(achievement.emoji)
                .font(.title)
                .frame(width: 40, height: 40)
                .background(achievement.isCompleted ? Color(UIColor.systemBlue).opacity(0.1) : Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // 完成状态
                    if achievement.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(UIColor.systemGreen))
                            
                            Text(achievement.completionDate?.formatted(date: .numeric, time: .omitted) ?? "")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    } else {
                        // 进度百分比
                        Text("\(Int(achievement.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
                
                // 进度条（仅对未完成的成就显示）
                if !achievement.isCompleted {
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 4)
                            .foregroundColor(Color(UIColor.systemGray5))
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: CGFloat(achievement.progress) * (UIScreen.main.bounds.width - 100), height: 4)
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 8)
    }
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