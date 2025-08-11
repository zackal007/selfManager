//
//  GoalPopupView.swift
//  selfManager
//
//  Created by Assistant on 2024.12.19.
//

import SwiftUI
import SwiftData
// 导入共享组件
import Foundation

struct GoalPopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 查询所有未删除的目标
    @Query(filter: #Predicate<Goal> { $0.isDeleted == false },
           sort: \Goal.createTime, order: .reverse) private var allGoals: [Goal]
    
    // 筛选器状态
    @Binding var goalFilterExpanded: Bool
    @Binding var selectedGoalType: GoalType?
    @Binding var selectedImportance: GoalImportance?
    @Binding var savedFilteredGoals: [Goal]
    @Binding var searchText: String
    
    // 保存筛选设置
    func saveFilterSettings() {
        savedFilteredGoals = filteredGoals
        
        // 保存筛选条件到 UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(goalFilterExpanded, forKey: "goalFilterExpanded")
        defaults.set(selectedGoalType?.rawValue, forKey: "selectedGoalType")
        defaults.set(selectedImportance?.rawValue as Int?, forKey: "selectedImportance")
        defaults.set(searchText, forKey: "goalSearchText")
    }
    
    // 计算筛选后的目标
    private var filteredGoals: [Goal] {
        allGoals.filter { goal in
            // 应用类型筛选
            let typeMatches = selectedGoalType == nil || goal.goalType == selectedGoalType
            
            // 应用优先级筛选
            let importanceMatches = selectedImportance == nil || goal.goalImportance == selectedImportance
            
            // 应用搜索文本筛选
            let searchMatches = searchText.isEmpty ||
                goal.name.localizedCaseInsensitiveContains(searchText) ||
                goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            return typeMatches && importanceMatches && searchMatches
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器部分
                VStack {
                    HStack {
                        Text("筛选器")
                            .font(.headline)
                            .foregroundColor(Color(UIColor.label))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                goalFilterExpanded.toggle()
                            }
                        }) {
                            Image(systemName: goalFilterExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(Color(UIColor.systemBlue))
                                .padding(8)
                                .background(Color(UIColor.systemBlue).opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if goalFilterExpanded {
                        // 搜索框
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color(UIColor.systemGray))
                            
                            TextField("搜索目标", text: $searchText)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(UIColor.systemGray))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // 目标类型筛选
                        VStack(alignment: .leading, spacing: 8) {
                            Text("目标类型")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // 全部选项
                                    FilterChip(title: "全部", isSelected: selectedGoalType == nil) {
                                        selectedGoalType = nil
                                    }
                                    
                                    // 各种目标类型
                                    ForEach(GoalType.allCases, id: \.self) { type in
                                        FilterChip(title: type.rawValue, isSelected: selectedGoalType == type) {
                                            selectedGoalType = type
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        
                        // 优先级筛选
                        VStack(alignment: .leading, spacing: 8) {
                            Text("优先级")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // 全部选项
                                    FilterChip(title: "全部", isSelected: selectedImportance == nil) {
                                        selectedImportance = nil
                                    }
                                    
                                    // 各种优先级
                                    ForEach(GoalImportance.allCases, id: \.self) { importance in
                                        FilterChip(
                                            title: importance.displayName,
                                            isSelected: selectedImportance == importance,
                                            color: importance.color
                                        ) {
                                            selectedImportance = importance
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom)
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top)
                
                // 目标列表
                if filteredGoals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Color(UIColor.systemGray))
                        
                        Text("没有找到匹配的目标")
                            .font(.headline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Button(action: {
                            // 重置筛选条件
                            selectedGoalType = nil
                            selectedImportance = nil
                            searchText = ""
                            // 保存重置后的筛选条件
                            saveFilterSettings()
                        }) {
                            Text("清除筛选条件")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor.systemBlue))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemBlue).opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                } else {
                    List {
                        ForEach(filteredGoals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("近期目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // 保存筛选结果
                        saveFilterSettings()
                        dismiss()
                    }) {
                        Text("保存筛选")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.systemGray))
                    }
                }
            }
            .onDisappear {
                // 在视图消失时保存筛选设置
                saveFilterSettings()
            }
        }
    }
}

// FilterChip组件已移至SharedComponents.swift

// 目标行视图组件
struct GoalRowView: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 12) {
            // 优先级指示器
            Image(systemName: goal.goalImportance.iconName)
                .foregroundColor(goal.goalImportance.color)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                // 目标名称
                Text(goal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)
                
                // 目标类型和进度
                HStack(spacing: 8) {
                    // 目标类型标签
                    Text(goal.goalType.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.systemGray))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(4)
                    
                    // 进度文本
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(goal.progress >= 1.0 ? Color(UIColor.systemGreen) : Color(UIColor.systemBlue))
                }
            }
            
            Spacer()
            
            // 进度环形指示器
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 3)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .trim(from: 0, to: CGFloat(goal.progress))
                    .stroke(goal.progress >= 1.0 ? Color(UIColor.systemGreen) : Color(UIColor.systemBlue), lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                
                if goal.progress >= 1.0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GoalPopupView(
        goalFilterExpanded: .constant(true),
        selectedGoalType: .constant(nil),
        selectedImportance: .constant(nil),
        savedFilteredGoals: .constant([]),
        searchText: .constant("")
    )
    .modelContainer(for: Goal.self, inMemory: true)
}