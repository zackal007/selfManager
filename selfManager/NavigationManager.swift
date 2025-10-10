//
//  NavigationManager.swift
//  selfManager
//
//  Created by Assistant on 2025.1.10.
//

import SwiftUI
import Foundation

/// 导航状态管理器
/// 用于跟踪各个模块的导航栈状态，实现二次点击返回顶层功能
class NavigationManager: ObservableObject {
    /// 单例实例
    static let shared = NavigationManager()
    
    /// 各模块的导航路径
    @Published var homeNavigationPath = NavigationPath()
    @Published var goalNavigationPath = NavigationPath()
    @Published var recordNavigationPath = NavigationPath()
    @Published var contactNavigationPath = NavigationPath()
    
    /// 记录上次点击标签的时间
    private var lastTabTapTimes: [Int: Date] = [:]
    
    /// 二次点击的时间间隔阈值（秒）
    private let doubleTapTimeInterval: TimeInterval = 0.5
    
    private init() {}

    /// 弹出当前标签栈的最后一个路由
    /// - Parameter tabIndex: 模块索引（0:首页 1:目标 2:记录 3:人脉）
    func pop(for tabIndex: Int) {
        switch tabIndex {
        case 0:
            if !homeNavigationPath.isEmpty { homeNavigationPath.removeLast() }
        case 1:
            if !goalNavigationPath.isEmpty { goalNavigationPath.removeLast() }
        case 2:
            if !recordNavigationPath.isEmpty { recordNavigationPath.removeLast() }
        case 3:
            if !contactNavigationPath.isEmpty { contactNavigationPath.removeLast() }
        default:
            if !homeNavigationPath.isEmpty { homeNavigationPath.removeLast() }
        }
    }
    
    /// 处理标签点击事件
    /// - Parameters:
    ///   - tabIndex: 被点击的标签索引
    ///   - currentTab: 当前选中的标签索引
    /// - Returns: 是否应该返回到顶层
    func handleTabTap(tabIndex: Int, currentTab: Int) -> Bool {
        let now = Date()
        
        // 如果点击的是当前已选中的标签
        if tabIndex == currentTab {
            // 检查是否为二次点击
            if let lastTapTime = lastTabTapTimes[tabIndex],
               now.timeIntervalSince(lastTapTime) <= doubleTapTimeInterval {
                // 二次点击，返回顶层
                popToRoot(for: tabIndex)
                lastTabTapTimes[tabIndex] = nil // 重置点击时间
                return true
            } else {
                // 首次点击或超时，记录时间
                lastTabTapTimes[tabIndex] = now
                return false
            }
        } else {
            // 点击的是其他标签，清除当前标签的点击记录
            lastTabTapTimes[currentTab] = nil
            return false
        }
    }
    
    /// 返回指定模块的顶层
    /// - Parameter tabIndex: 模块索引
    private func popToRoot(for tabIndex: Int) {
        switch tabIndex {
        case 0: // 首页
            homeNavigationPath = NavigationPath()
        case 1: // 目标
            goalNavigationPath = NavigationPath()
        case 2: // 记录
            recordNavigationPath = NavigationPath()
        case 3: // 人脉
            contactNavigationPath = NavigationPath()
        default:
            break
        }
    }
    
    /// 获取指定模块的导航路径
    /// - Parameter tabIndex: 模块索引
    /// - Returns: 对应的导航路径绑定
    func getNavigationPath(for tabIndex: Int) -> Binding<NavigationPath> {
        switch tabIndex {
        case 0:
            return Binding(
                get: { self.homeNavigationPath },
                set: { self.homeNavigationPath = $0 }
            )
        case 1:
            return Binding(
                get: { self.goalNavigationPath },
                set: { self.goalNavigationPath = $0 }
            )
        case 2:
            return Binding(
                get: { self.recordNavigationPath },
                set: { self.recordNavigationPath = $0 }
            )
        case 3:
            return Binding(
                get: { self.contactNavigationPath },
                set: { self.contactNavigationPath = $0 }
            )
        default:
            return Binding(
                get: { self.homeNavigationPath },
                set: { self.homeNavigationPath = $0 }
            )
        }
    }
    
    /// 检查指定模块是否在顶层
    /// - Parameter tabIndex: 模块索引
    /// - Returns: 是否在顶层
    func isAtRoot(for tabIndex: Int) -> Bool {
        switch tabIndex {
        case 0:
            return homeNavigationPath.isEmpty
        case 1:
            return goalNavigationPath.isEmpty
        case 2:
            return recordNavigationPath.isEmpty
        case 3:
            return contactNavigationPath.isEmpty
        default:
            return true
        }
    }
    
    /// 清除所有导航状态
    func clearAllNavigationPaths() {
        homeNavigationPath = NavigationPath()
        goalNavigationPath = NavigationPath()
        recordNavigationPath = NavigationPath()
        contactNavigationPath = NavigationPath()
        lastTabTapTimes.removeAll()
    }
}

/// 导航路径扩展，提供便捷方法
extension NavigationPath {
    /// 检查导航路径是否为空
    var isEmpty: Bool {
        return count == 0
    }
}