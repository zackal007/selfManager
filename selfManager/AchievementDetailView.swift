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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Achievement.completionDate, order: .reverse) private var achievements: [Achievement]
    
    // 选中的分类
    @State private var selectedCategory: String? = nil
    
    // 显示模式
    @State private var showMode: ShowMode = .all
    
    // 编辑状态
    @State private var isEditing = false
    @State private var showingAddSheet = false
    @State private var newAchievement = Achievement(emoji: "🏆", name: "", achievementDescription: "", category: "个人成长", isCompleted: false)
    
    // Toast提示
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSuccess = false
    
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
            ZStack {
                VStack(spacing: 0) {
                    // 内容区域
                    ScrollView {
                        VStack(spacing: 16) {
                            // 成就统计卡片
                            achievementStatsCard
                                .padding(.horizontal)
                            
                            // 分类选择器
                            categorySelector
                                .padding(.horizontal)
                            
                            // 成就列表
                            achievementList
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                
                // Toast提示
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage, isSuccess: isSuccess)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showToast = false
                                    }
                                }
                            }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showToast)
                    .zIndex(1)
                }
            }
            .navigationTitle("成就中心")
            .navigationBarTitleDisplayMode(.inline)
            .padding(.top, 8)
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
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("基本信息")) {
                            TextField("成就名称", text: $newAchievement.name)
                                .padding(.vertical, 4)
                            TextField("成就描述", text: $newAchievement.achievementDescription)
                                .padding(.vertical, 4)
                            TextField("表情图标", text: $newAchievement.emoji)
                                .padding(.vertical, 4)
                        }
                        
                        Section(header: Text("分类")) {
                            Picker("选择分类", selection: $newAchievement.category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                        }
                        
                        // 移除进度相关字段，避免添加失败
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
                                do {
                                    if let editingAchievement = achievements.first(where: { $0.id == newAchievement.id }) {
                                        // 编辑模式
                                        editingAchievement.emoji = newAchievement.emoji
                                        editingAchievement.name = newAchievement.name
                                        editingAchievement.achievementDescription = newAchievement.achievementDescription
                                        editingAchievement.category = newAchievement.category
                                        editingAchievement.isCompleted = newAchievement.isCompleted
                                        editingAchievement.completionDate = newAchievement.completionDate
                                        toastMessage = "成就更新成功"
                                    } else {
                                        // 新增
                                        if newAchievement.name.isEmpty {
                                            toastMessage = "成就名称不能为空"
                                            isSuccess = false
                                            showToast = true
                                            return
                                        }
                                        
                                        let achievement = Achievement(
                                            emoji: newAchievement.emoji,
                                            name: newAchievement.name,
                                            achievementDescription: newAchievement.achievementDescription,
                                            category: newAchievement.category,
                                            isCompleted: newAchievement.isCompleted,
                                            completionDate: newAchievement.completionDate
                                        )
                                        modelContext.insert(achievement)
                                        toastMessage = "成就添加成功"
                                    }
                                    try modelContext.save()
                                    isSuccess = true
                                    showingAddSheet = false
                                    showToast = true
                                } catch {
                                    toastMessage = "保存失败：\(error.localizedDescription)"
                                    isSuccess = false
                                    showToast = true
                                }
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
                    newAchievement = Achievement(emoji: "🏆", name: "", achievementDescription: "", category: "个人成长", isCompleted: false)
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
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
                                            modelContext.delete(achievementToRemove)
                                            try? modelContext.save()
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
                
                Text(achievement.achievementDescription)
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
                    // 未完成状态显示，移除进度条
                    Text("未完成")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.systemOrange))
                }
            }
            
            // 编辑模式下可加其他操作
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
@Model
final class Achievement: Identifiable, ObservableObject {
    @Attribute(.unique) var id: UUID = UUID()
    @Attribute var emoji: String = ""
    @Attribute var name: String = ""
    @Attribute var achievementDescription: String = ""
    @Attribute var category: String = "个人成长"
    @Attribute var isCompleted: Bool = false
    @Attribute var completionDate: Date? = nil
    
    init(emoji: String = "", name: String = "", achievementDescription: String = "", category: String = "个人成长", isCompleted: Bool = false, completionDate: Date? = nil) {
        self.emoji = emoji
        self.name = name
        self.achievementDescription = achievementDescription
        self.category = category
        self.isCompleted = isCompleted
        self.completionDate = completionDate
    }
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