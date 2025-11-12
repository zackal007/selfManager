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
    
    enum ActiveAlert: Identifiable {
        case restore
        case permanentDelete
        case emptyTrash
        var id: Int {
            switch self {
            case .restore: return 1
            case .permanentDelete: return 2
            case .emptyTrash: return 3
            }
        }
    }
    @State private var activeAlert: ActiveAlert?
    @State private var selectedGoal: Goal?
    
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
                        
                        Text("删除的目标会在这里保留\(getTrashExpirationDays())天")
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
                                activeAlert = .restore
                            } onPermanentDelete: {
                                selectedGoal = goal
                                activeAlert = .permanentDelete
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
                            activeAlert = .emptyTrash
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .restore:
                return Alert(
                    title: Text("恢复目标"),
                    message: Text("确定要恢复目标「\(selectedGoal?.name ?? "")」吗？"),
                    primaryButton: .cancel(Text("取消")),
                    secondaryButton: .default(Text("恢复"), action: {
                        if let goal = selectedGoal {
                            restoreGoal(goal)
                        }
                        selectedGoal = nil
                        activeAlert = nil
                    })
                )
            case .permanentDelete:
                return Alert(
                    title: Text("永久删除"),
                    message: Text("确定要永久删除目标「\(selectedGoal?.name ?? "")」吗？此操作无法撤销。"),
                    primaryButton: .cancel(Text("取消")),
                    secondaryButton: .destructive(Text("删除"), action: {
                        if let goal = selectedGoal {
                            permanentlyDeleteGoal(goal)
                        }
                        selectedGoal = nil
                        activeAlert = nil
                    })
                )
            case .emptyTrash:
                return Alert(
                    title: Text("清空回收站"),
                    message: Text("确定要清空回收站吗？这将永久删除所有已删除的目标，此操作无法撤销。"),
                    primaryButton: .cancel(Text("取消")),
                    secondaryButton: .destructive(Text("清空"), action: {
                        emptyTrash()
                        selectedGoal = nil
                        activeAlert = nil
                    })
                )
            }
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
    
    // 获取用户设置的回收站过期天数
    private func getTrashExpirationDays() -> Int {
        return TrashCleanupService.shared.getUserTrashExpirationDays(modelContext: modelContext)
    }
}

struct TrashGoalRow: View {
    @Environment(\.modelContext) private var modelContext
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
        
        // 获取用户设置的过期天数
        let expirationDays = TrashCleanupService.shared.getUserTrashExpirationDays(modelContext: modelContext)
        
        let calendar = Calendar.current
        let daysSinceDeletion = calendar.dateComponents([.day], from: deletedDate, to: Date()).day ?? 0
        let daysRemaining = expirationDays - daysSinceDeletion
        return max(0, daysRemaining)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 目标信息
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                
                Text(goal.goalDescription)
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(2)
                
                // 删除时间和剩余天数
                VStack(alignment: .leading, spacing: 2) {
                    if daysUntilPermanentDeletion > 0 {
                        Text("\(daysUntilPermanentDeletion)天后永久删除")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemOrange))
                    } else {
                        Text("即将永久删除")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemRed))
                    }
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onRestore) {
                    Text("恢复")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onPermanentDelete) {
                    Text("永久删除")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemRed))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemRed).opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    
    TrashView()
        .modelContainer(container)
}