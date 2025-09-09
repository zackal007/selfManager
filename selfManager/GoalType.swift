//
//  GoalType.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftUI

/// 目标类型枚举
public enum GoalType: String, Codable, CaseIterable {
    /// 人生目标
    case life = "人生目标"
    /// 年度目标
    case yearly = "年度目标"
    /// 短期目标
    case shortTerm = "短期目标"
    /// 习惯
    case habit = "习惯"
    
    /// 获取所有目标类型的数组
    public static var allCases: [GoalType] {
        return [.life, .yearly, .shortTerm, .habit]
    }
    
    /// 根据字符串创建GoalType，如果无法匹配则返回短期目标
    static func from(string: String) -> GoalType {
        return GoalType.allCases.first { $0.rawValue == string } ?? .shortTerm
    }
    
    /// 根据类别字符串推断目标类型
    static func inferFromCategory(_ category: String) -> GoalType {
        if category.contains("人生") {
            return .life
        } else if category.contains("年度") {
            return .yearly
        } else if category.contains("习惯") {
            return .habit
        } else {
            return .shortTerm
        }
    }
    
    /// 获取与目标类型关联的颜色
    var color: Color {
        switch self {
        case .life:
            return Color.purple
        case .yearly:
            return Color.blue
        case .shortTerm:
            return Color.orange
        case .habit:
            return Color.green
        }
    }
}