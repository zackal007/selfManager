//
//  TestHabitGoalIntegration.swift
//  selfManager
//
//  Created by Assistant on 2024.10.24.
//

import SwiftUI
import SwiftData

/// 测试习惯目标集成功能的视图
struct TestHabitGoalIntegrationView: View {
    @Query(sort: \Goal.modifyTime, order: .reverse) var allGoals: [Goal]
    @Query(filter: #Predicate<Habit> { habit in
        !habit.isDeleted && habit.isActive
    }, sort: \Habit.modifyTime, order: .reverse) var habits: [Habit]
    
    // 计算属性：过滤出目标类型为习惯的目标
    private var habitGoals: [Goal] {
        return allGoals.filter { goal in
            !goal.isDeleted && goal.goalType == .habit
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("习惯目标集成测试")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("统计信息")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("习惯数量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(habits.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("习惯目标数量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(habitGoals.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if !habitGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("习惯类型的目标")
                            .font(.headline)
                        
                        ForEach(habitGoals) { goal in
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading) {
                                    Text(goal.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text("进度: \(Int(goal.progress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("习惯")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 2)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("没有找到习惯类型的目标")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("请在目标页面创建一个目标类型为"习惯"的目标来测试集成功能")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("集成测试")
        }
    }
}

#Preview {
    TestHabitGoalIntegrationView()
        .modelContainer(for: [Goal.self, Habit.self])
}