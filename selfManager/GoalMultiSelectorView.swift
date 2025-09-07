//
//  GoalMultiSelectorView.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import SwiftData

struct GoalMultiSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var contact: Contact
    var allGoals: [Goal]
    
    @State private var searchText = ""
    
    // 计算筛选后的目标
    private var filteredGoals: [Goal] {
        if searchText.isEmpty {
            return allGoals
        } else {
            return allGoals.filter { goal in
                goal.name.localizedCaseInsensitiveContains(searchText) ||
                goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                goal.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索目标", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 已选目标
                if !contact.relatedGoalIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已选目标")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(contact.relatedGoalIds, id: \.self) { goalId in
                                    if let goal = allGoals.first(where: { $0.id == goalId }) {
                                        HStack {
                                            Text(goal.name)
                                                .font(.system(size: 14))
                                            
                                            Button(action: {
                                                removeGoal(goalId)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(15)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // 目标列表
                List {
                    ForEach(filteredGoals) { goal in
                        MultipleSelectionGoalRow(
                            goal: goal,
                            isSelected: contact.relatedGoalIds.contains(goal.id),
                            action: {
                                toggleGoalSelection(goal.id)
                            }
                        )
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("选择关联目标", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("完成") {
                    saveChanges()
                    dismiss()
                }
            )
        }
    }
    
    // 切换目标选择状态
    private func toggleGoalSelection(_ goalId: UUID) {
        if contact.relatedGoalIds.contains(goalId) {
            removeGoal(goalId)
        } else {
            addGoal(goalId)
        }
    }
    
    // 添加目标
    private func addGoal(_ goalId: UUID) {
        if !contact.relatedGoalIds.contains(goalId) {
            var newRelatedGoalIds = contact.relatedGoalIds
            newRelatedGoalIds.append(goalId)
            contact.relatedGoalIds = newRelatedGoalIds
            
            // 双向关联：更新目标的关联联系人
            if let goal = allGoals.first(where: { $0.id == goalId }) {
                var goalRelatedContactIds = goal.relatedContactIds
                if !goalRelatedContactIds.contains(contact.id) {
                    goalRelatedContactIds.append(contact.id)
                    goal.relatedContactIds = goalRelatedContactIds
                    
                    // 记录关联联系人添加
                    GoalActivityManager.shared.logContactAdd(goal: goal, contactId: contact.id, contactName: contact.name, modelContext: modelContext)
                }
            }
        }
    }
    
    // 移除目标
    private func removeGoal(_ goalId: UUID) {
        if let index = contact.relatedGoalIds.firstIndex(of: goalId) {
            var newRelatedGoalIds = contact.relatedGoalIds
            newRelatedGoalIds.remove(at: index)
            contact.relatedGoalIds = newRelatedGoalIds
            
            // 双向关联：更新目标的关联联系人
            if let goal = allGoals.first(where: { $0.id == goalId }) {
                var goalRelatedContactIds = goal.relatedContactIds
                if let contactIndex = goalRelatedContactIds.firstIndex(of: contact.id) {
                    goalRelatedContactIds.remove(at: contactIndex)
                    goal.relatedContactIds = goalRelatedContactIds
                    
                    // 记录关联联系人删除
                    GoalActivityManager.shared.logContactRemove(goal: goal, contactId: contact.id, contactName: contact.name, modelContext: modelContext)
                }
            }
        }
    }
    
    // 保存更改
    private func saveChanges() {
        try? modelContext.save()
    }
}

// 多选行组件
struct MultipleSelectionGoalRow: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(goal.name)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}