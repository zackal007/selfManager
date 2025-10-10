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

    // 近7天与本月统计
    private var weeklyCompletedCount: Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        return achievements.filter { $0.isCompleted && ($0.completionDate ?? Date.distantPast) >= start }.count
    }

    private var monthlyCompletedCount: Int {
        let cal = Calendar.current
        let now = Date()
        guard let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        return achievements.filter { $0.isCompleted && ($0.completionDate ?? Date.distantPast) >= startOfMonth }.count
    }

    private var last7DaysCompletionCounts: [Int] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
            return achievements.filter { ach in
                guard ach.isCompleted, let d = ach.completionDate else { return false }
                return cal.isDate(d, inSameDayAs: day)
            }.count
        }.reversed()
    }
    
    // 连续达成统计（以天为单位）
    private var completionDays: Set<DateComponents> {
        let cal = Calendar.current
        return Set(achievements.compactMap { ach in
            guard ach.isCompleted, let d = ach.completionDate else { return nil }
            return cal.dateComponents([.year, .month, .day], from: d)
        })
    }
    private var currentStreakDays: Int {
        let cal = Calendar.current
        var count = 0
        var cursor = cal.startOfDay(for: Date())
        while completionDays.contains(cal.dateComponents([.year, .month, .day], from: cursor)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
    private var longestStreakDays: Int {
        let cal = Calendar.current
        let sorted = completionDays.compactMap { cal.date(from: $0) }.sorted()
        var best = 0
        var cur = 0
        var prevDate: Date? = nil
        for d in sorted {
            if let prev = prevDate, let next = cal.date(byAdding: .day, value: 1, to: prev), cal.isDate(d, inSameDayAs: next) {
                cur += 1
            } else {
                cur = 1
            }
            best = max(best, cur)
            prevDate = d
        }
        return best
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
                            // 成就统计（标题 + 概览卡）
                            Text("成就统计")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            achievementOverviewCard
                                .padding(.horizontal)
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

    // 加强版统计卡片：本周、本月与近7天趋势
    private var achievementAdvancedStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                completionRateRing
                VStack(spacing: 6) {
                    Text("连续达成")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    HStack(spacing: 8) {
                        Text("\(currentStreakDays)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemGreen))
                        Text("天")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    Text("历史最长：\(longestStreakDays)天")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGreen).opacity(0.08))
                .cornerRadius(12)

                statTile(title: "本周完成", value: weeklyCompletedCount, color: Color(UIColor.systemGreen))
                statTile(title: "本月完成", value: monthlyCompletedCount, color: Color(UIColor.systemBlue))
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("近7天趋势")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                miniBarChart(values: last7DaysCompletionCounts, barColor: .accentColor)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // 统计瓦片
    private func statTile(title: String, value: Int? = nil, valueText: String? = nil, color: Color) -> some View {
        VStack(spacing: 6) {
            if let v = value {
                Text("\(v)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            } else if let t = valueText {
                Text(t)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // 迷你柱状图组件
    private func miniBarChart(values: [Int], barColor: Color) -> some View {
        let maxV = max(values.max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(values.indices, id: \.self) { i in
                let v = values[i]
                let h = CGFloat(v) / CGFloat(maxV)
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: 14, height: max(8, 40 * h))
                    .opacity(v == 0 ? 0.35 : 1.0)
            }
        }
        .frame(height: 44)
    }

    // 完成率环形仪表
    private var completionRateRing: some View {
        let pct = completionRate
        return ZStack {
            Circle()
                .stroke(Color(UIColor.systemGray5), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(pct))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("完成率")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
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
                // 两列卡片栅格，贴近参考截图的呈现
                let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
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
    
    // 成就行视图
    private func achievementRow(_ achievement: Achievement) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Emoji图标
                Text(achievement.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.name)
                        .font(.headline)
                    Text(achievement.achievementDescription)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                }
                Spacer()
                if achievement.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            }
            
            // 线性进度：已完成100%，未完成0%
            HStack {
                let pct = achievement.isCompleted ? 1.0 : 0.0
                let numerator = achievement.isCompleted ? 1 : 0
                Text("\(numerator)/1")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            linearProgress(pct: achievement.isCompleted ? 1.0 : 0.0, color: Color(UIColor.systemBlue))
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        .contentShape(Rectangle())
    }
    
    // 概览卡：总成就数与解锁率
    private var achievementOverviewCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("总成就数")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(completedCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.label))
                        Text("/ \(totalCount)")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    linearProgress(
                        pct: totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0,
                        color: Color(UIColor.systemBlue)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("解锁率")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f", completionRate * 100))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.label))
                        Text("%")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.systemGreen))
                        Text("近7天 \(weeklyCompletedCount) 次")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // 通用线性进度条
    private func linearProgress(pct: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(pct)), height: 8)
            }
        }
        .frame(height: 8)
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