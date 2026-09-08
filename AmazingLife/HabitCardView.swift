//
//  HabitCardView.swift
//  selfManager
//
//  Created by Assistant on 2025/1/17.
//

import SwiftUI
import SwiftData

// 习惯显示项枚举
enum HabitDisplayItem: Identifiable {
    case habit(Habit)
    case goal(Goal)
    
    var id: UUID {
        switch self {
        case .habit(let habit):
            return habit.id
        case .goal(let goal):
            return goal.id
        }
    }
    
    var name: String {
        switch self {
        case .habit(let habit):
            return habit.name
        case .goal(let goal):
            return goal.name
        }
    }
}

// 从 HomeView 中引用的类型定义
typealias HomeCardID = HomeView.HomeCardID
typealias HomeCardType = HomeView.HomeCardType
typealias HomeCardSize = HomeView.HomeCardSize

struct HabitCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { habit in
        !habit.isDeleted && habit.isActive
    }, sort: \Habit.modifyTime, order: .reverse) var habits: [Habit]
    
    // 添加查询所有目标，然后在计算属性中过滤
    @Query(sort: \Goal.modifyTime, order: .reverse) var allGoals: [Goal]
    
    // 添加卡片尺寸相关的参数
    let cardSizesByID: [HomeCardID: HomeCardSize]
    let defaultSizeForID: (HomeCardID) -> HomeCardSize
    
    init(cardSizesByID: [HomeCardID: HomeCardSize], defaultSizeForID: @escaping (HomeCardID) -> HomeCardSize) {
        self.cardSizesByID = cardSizesByID
        self.defaultSizeForID = defaultSizeForID
    }
    
    // 计算属性：过滤出目标类型为习惯的目标
    private var habitGoals: [Goal] {
        return allGoals.filter { goal in
            !goal.isDeleted && goal.goalType == .habit
        }
    }
    
    // 合并习惯和目标的数据源
    private var displayItems: [HabitDisplayItem] {
        var items: [HabitDisplayItem] = []
        
        // 添加习惯项
        for habit in habits {
            items.append(.habit(habit))
        }
        
        // 添加习惯目标项
        for goal in habitGoals {
            items.append(.goal(goal))
        }
        
        return items
    }
    
    var body: some View {
        NavigationLink(destination: HabitDetailView()) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemGreen))
                    Text("home_card_habit_title".localized)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                                                            
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.systemGray))
                }
                
                // 根据卡片尺寸展示不同数量的习惯内容
                let idForSize = HomeCardID.type(.habit)
                let size = cardSizesByID[idForSize] ?? defaultSizeForID(idForSize)
                let displayCount: Int = {
                    switch size {
                    case .small: return 2   // 1×1 显示 2 条
                    case .medium: return 6  // 1×2 显示 6 条
                    case .large: return 12  // 2×2 显示 12 条
                    }
                }()
                let limitedItems = Array(displayItems.prefix(displayCount))

                if displayItems.isEmpty {
                    Text("empty_no_habits".localized)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(limitedItems) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(DesignToken.cornerRadiusTertiary)
                            .shadow(color: Color(UIColor.label).opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                    }
                }

            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(DesignToken.cornerRadius)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 习惯详情视图
struct HabitDetailView: View {
    @Query(filter: #Predicate<Habit> { habit in
        !habit.isDeleted && habit.isActive
    }, sort: \Habit.modifyTime, order: .reverse) var habits: [Habit]
    
    // 添加查询所有目标，然后在计算属性中过滤
    @Query(sort: \Goal.modifyTime, order: .reverse) var allGoals: [Goal]
    
    // 计算属性：过滤出目标类型为习惯的目标
    private var habitGoals: [Goal] {
        return allGoals.filter { goal in
            !goal.isDeleted && goal.goalType == .habit
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
                LazyVStack(spacing: 16) {
                    // 习惯统计卡片
                    HabitStatsCard(habits: habits, habitGoals: habitGoals)
                    
                    // 习惯列表
                    if !habits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("my_habits".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(habits) { habit in
                                    HabitGoalDetailCard(item: .habit(habit))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 习惯目标列表
                    if !habitGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("habit_goals".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(habitGoals) { goal in
                                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                                        HabitGoalDetailCard(item: .goal(goal))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if habits.isEmpty && habitGoals.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "plus.circle.dashed")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("no_habits".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("start_first_habit".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("habit_center".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text("back".localized)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .gesture(
                DragGesture().onEnded { gesture in
                    if gesture.translation.width > 100 {
                        dismiss()
                    }
                }
            )
        }
    }

// 习惯统计卡片
struct HabitStatsCard: View {
    let habits: [Habit]
    let habitGoals: [Goal]
    
    private var todayCompletedCount: Int {
        habits.filter { $0.isCompletedToday() }.count
    }
    
    private var totalHabits: Int {
        habits.count + habitGoals.count
    }
    
    private var averageProgress: Double {
        guard !habitGoals.isEmpty else { return 0 }
        return habitGoals.reduce(0) { $0 + $1.progress } / Double(habitGoals.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日概览")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatItemView(
                    title: "今日完成",
                    value: "\(todayCompletedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatItemView(
                    title: "总习惯",
                    value: "\(totalHabits)",
                    icon: "repeat.circle.fill",
                    color: .blue
                )
                
                StatItemView(
                    title: "平均进度",
                    value: "\(Int(averageProgress * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(DesignToken.cornerRadius)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// 统计项视图
struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 习惯目标详情卡片
struct HabitGoalDetailCard: View {
    let item: HabitDisplayItem
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                switch item {
                case .habit(let habit):
                    Image(systemName: habit.icon)
                        .font(.title2)
                        .foregroundColor(Color.habitColor(from: habit.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name.isEmpty ? "unnamed_habit".localized : habit.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text("streak_days_prefix".localized + String(habit.currentStreak) + "days_unit".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if habit.isCompletedToday() {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    } else {
                        Button(action: {
                            completeHabit(habit)
                        }) {
                            Image(systemName: "circle")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                case .goal(let goal):
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name.isEmpty ? "unnamed_goal".localized : goal.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text("progress_prefix".localized + String(Int(goal.progress * 100)) + "%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(DesignToken.cornerRadiusMedium)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 2, x: 0, y: 1)
    }
    
    private func completeHabit(_ habit: Habit) {
        let record = HabitRecord()
        record.habit = habit
        modelContext.insert(record)
        
        habit.totalCompletions += 1
        habit.updateStreak()
        
        do {
            try modelContext.save()
        } catch {
            print("保存习惯记录失败: \(error)")
        }
    }
}

// ... existing code ...