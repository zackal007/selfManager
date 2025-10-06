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
    @Binding var selectedTags: Set<String>
    
    // 保存筛选设置
    func saveFilterSettings() {
        savedFilteredGoals = filteredGoals
        
        // 保存筛选条件到 UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(goalFilterExpanded, forKey: "goalFilterExpanded")
        defaults.set(selectedGoalType?.rawValue, forKey: "selectedGoalType")
        defaults.set(selectedImportance?.rawValue as Int?, forKey: "selectedImportance")
        defaults.set(searchText, forKey: "goalSearchText")
        defaults.set(Array(selectedTags), forKey: "goalFilterTags")
    }
    
    // 计算筛选后的目标
    private var filteredGoals: [Goal] {
        allGoals.filter { goal in
            // 应用类型筛选
            let typeMatches = selectedGoalType == nil || goal.goalType == selectedGoalType
            
            // 应用优先级筛选
            let importanceMatches = selectedImportance == nil || goal.goalImportance == selectedImportance
            
            // 应用标签筛选（任意匹配一个标签即可）
            let tagMatches = selectedTags.isEmpty || goal.tags.contains { selectedTags.contains($0) }

            // 应用搜索文本筛选
            let searchMatches = searchText.isEmpty ||
                goal.name.localizedCaseInsensitiveContains(searchText) ||
                goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            return typeMatches && importanceMatches && tagMatches && searchMatches
        }
    }

    // 可选标签列表（去重后按字母排序）
    private var availableTags: [String] {
        Array(Set(allGoals.flatMap { $0.tags })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器部分（移除“筛选器”标签与展开/收起按钮，默认展开）
                VStack {
                    // 默认展开内容
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
                    .padding(.top)
                    
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
                                ForEach(GoalImportance.allCases.filter { $0 != .critical }, id: \.self) { importance in
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
                    
                    // 标签筛选
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // 全部选项
                                FilterChip(title: "全部", isSelected: selectedTags.isEmpty) {
                                    selectedTags.removeAll()
                                }
                                
                                ForEach(availableTags, id: \.self) { tag in
                                    FilterChip(title: tag, isSelected: selectedTags.contains(tag)) {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom)
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color(UIColor.label).opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top)
                
                // 移除筛选结果展示区域，保留弹窗仅用于筛选条件设定
                Spacer()
            }
            .navigationTitle("目标筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 保存筛选结果
                        saveFilterSettings()
                        dismiss()
                    }) {
                        Text("确认")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
            }
            .onDisappear {
                // 在视图消失时保存筛选设置
                saveFilterSettings()
            }
            .onAppear {
                // 默认保持展开状态
                goalFilterExpanded = true
            }
            // 弹窗背景色统一
            .background(Color(UIColor.systemBackground))
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
        searchText: .constant(""),
        selectedTags: .constant([])
    )
    .modelContainer(for: Goal.self, inMemory: true)
}