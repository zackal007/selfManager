//
//  TrashCleanupService.swift
//  selfManager
//
//  Created by Assistant on 2024.12.19.
//

import Foundation
import SwiftData

/// 回收站清理服务
/// 负责自动清理超过30天的已删除目标
class TrashCleanupService {
    static let shared = TrashCleanupService()
    
    private init() {}
    
    /// 清理超过30天的已删除目标
    /// - Parameter modelContext: SwiftData模型上下文
    func cleanupExpiredGoals(modelContext: ModelContext) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        do {
            // 查询超过30天的已删除目标
            let descriptor = FetchDescriptor<Goal>(
                predicate: #Predicate<Goal> { goal in
                    goal.isDeleted == true &&                     
                    goal.deletedDate != nil && 
                    goal.deletedDate! < thirtyDaysAgo
                }
            )
            
            let expiredGoals = try modelContext.fetch(descriptor)
            
            // 永久删除这些目标
            for goal in expiredGoals {
                modelContext.delete(goal)
            }
            
            // 保存更改
            try modelContext.save()
            
            if !expiredGoals.isEmpty {
                print("自动清理了 \(expiredGoals.count) 个过期的回收站目标")
            }
            
        } catch {
            print("清理回收站失败: \(error)")
        }
    }
    
    /// 启动定期清理任务
    /// - Parameter modelContext: SwiftData模型上下文
    func startPeriodicCleanup(modelContext: ModelContext) {
        // 每24小时执行一次清理
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            self.cleanupExpiredGoals(modelContext: modelContext)
        }
        
        // 立即执行一次清理
        cleanupExpiredGoals(modelContext: modelContext)
    }
}