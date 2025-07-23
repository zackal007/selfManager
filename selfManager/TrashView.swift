//
//  TrashView.swift
//  selfManager
//
//  Created by Assistant on 2024.12.19.
//

import SwiftUI
import SwiftData

struct TrashView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 查询已删除的目标
    @Query(filter: #Predicate<Goal> { $0.isDeleted == true }, 
           sort: \Goal.deletedDate, order: .reverse) 
    private var deletedGoals: [Goal]
    
    @State private var showingRestoreAlert = false
    @State private var showingPermanentDeleteAlert = false
    @State private var selectedGoal: Goal?
    @State private var showingEmptyTrashAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if deletedGoals.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "trash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("回收站为空")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("删除的目标会在这里保留30天")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 目标列表
                    List {
                        ForEach(deletedGoals) { goal in
                            TrashGoalRow(goal: goal) {
                                selectedGoal = goal
                                showingRestoreAlert = true
                            } onPermanentDelete: {
                                selectedGoal = goal
                                showingPermanentDeleteAlert = true
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("回收站")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                if !deletedGoals.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空回收站") {
                            showingEmptyTrashAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("恢复目标", isPresented: $showingRestoreAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复") {
                if let goal = selectedGoal {
                    restoreGoal(goal)
                }
            }
        } message: {
            Text("确定要恢复目标「\(selectedGoal?.name ?? "")」吗？")
        }
        .alert("永久删除", isPresented: $showingPermanentDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let goal = selectedGoal {
                    permanentlyDeleteGoal(goal)
                }
            }
        } message: {
            Text("确定要永久删除目标「\(selectedGoal?.name ?? "")」吗？此操作无法撤销。")
        }
        .alert("清空回收站", isPresented: $showingEmptyTrashAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                emptyTrash()
            }
        } message: {
            Text("确定要清空回收站吗？这将永久删除所有已删除的目标，此操作无法撤销。")
        }
    }
    
    private func restoreGoal(_ goal: Goal) {
        goal.restoreFromTrash()
        
        do {
            try modelContext.save()
        } catch {
            print("恢复目标失败: \(error)")
        }
    }
    
    private func permanentlyDeleteGoal(_ goal: Goal) {
        modelContext.delete(goal)
        
        do {
            try modelContext.save()
        } catch {
            print("永久删除目标失败: \(error)")
        }
    }
    
    private func emptyTrash() {
        for goal in deletedGoals {
            modelContext.delete(goal)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("清空回收站失败: \(error)")
        }
    }
}

struct TrashGoalRow: View {
    let goal: Goal
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    
    private var deletedTimeText: String {
        guard let deletedDate = goal.deletedDate else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "删除于 " + formatter.localizedString(for: deletedDate, relativeTo: Date())
    }
    
    private var daysUntilPermanentDeletion: Int {
        guard let deletedDate = goal.deletedDate else { return 0 }
        
        let calendar = Calendar.current
        let daysSinceDeletion = calendar.dateComponents([.day], from: deletedDate, to: Date()).day ?? 0
        let daysRemaining = 30 - daysSinceDeletion
        return max(0, daysRemaining)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 目标信息
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(goal.goalDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 删除时间和剩余天数
                VStack(alignment: .leading, spacing: 2) {
                    Text(deletedTimeText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if daysUntilPermanentDeletion > 0 {
                        Text("\(daysUntilPermanentDeletion)天后永久删除")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("即将永久删除")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onRestore) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("恢复")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: onPermanentDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text("永久删除")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    
    TrashView()
        .modelContainer(container)
}