//
//  AppEnums.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation

// 视图模式枚举
enum ViewMode {
    case gallery // 画廊视图
    case list    // 列表视图
}

// 分类选项枚举
enum CategoryOption {
    case time  // 按时间分类
    case type  // 按类型分类
}

// 排序选项枚举
enum SortOption {
    case name       // 按名称排序
    case createTime // 按创建时间排序
    case modifyTime // 按修改时间排序
    case visitTime  // 按访问时间排序
    case importance // 按优先级排序
    case progress   // 按进度排序
}