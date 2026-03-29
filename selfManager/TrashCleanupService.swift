//
//  TrashCleanupService.swift
//  selfManager
//
//  Created by Assistant on 2024.12.19.
//

import Foundation
import SwiftData

/// 回收站清理服务
/// 负责自动清理超过指定天数的已删除目标
class TrashCleanupService {
    static let shared = TrashCleanupService()
    
    private init() {}
    
    /// 清理超过指定天数的已删除目标
    /// - Parameter modelContext: SwiftData模型上下文
    func cleanupExpiredGoals(modelContext: ModelContext) {
        // 获取用户设置的过期天数，默认为30天
        let expirationDays = getUserTrashExpirationDays(modelContext: modelContext)
        let expirationDate = Calendar.current.date(byAdding: .day, value: -expirationDays, to: Date()) ?? Date()
        
        do {
            // 查询超过指定天数的已删除目标
            let descriptor = FetchDescriptor<Goal>(
                predicate: #Predicate<Goal> { goal in
                    if let date = goal.deletedDate {
                        return goal.isDeleted == true && date < expirationDate
                    } else {
                        return false
                    }
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
    
    /// 获取用户设置的回收站过期天数
    /// - Parameter modelContext: SwiftData模型上下文
    /// - Returns: 过期天数，默认为30天
    func getUserTrashExpirationDays(modelContext: ModelContext) -> Int {
        do {
            // 查询用户设置
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            
            // 如果有用户设置，返回第一个用户的设置
            if let user = users.first {
                return user.trashExpirationDays
            }
        } catch {
            print("获取用户设置失败: \(error)")
        }
        
        // 默认返回30天
        return 30
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