//
//  LocalizationManager.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import Foundation
import SwiftUI
import Combine

// 支持的语言枚举
enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-CN"
    case english = "en-US"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
    
    var locale: Locale {
        return Locale(identifier: self.rawValue)
    }
}

// 国际化管理器
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            // 保存语言设置到UserDefaults
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            // 更新字符串资源
            updateLocalizedStrings()
            // 发送通知，通知所有观察者语言已更改
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    @Published var localizedStrings: [String: String] = [:]
    
    private init() {
        // 从UserDefaults加载保存的语言设置，默认为中文
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? AppLanguage.chinese.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .chinese
        
        // 初始化字符串资源
        updateLocalizedStrings()
    }
    
    // 更新本地化字符串资源
    private func updateLocalizedStrings() {
        switch currentLanguage {
        case .chinese:
            localizedStrings = ChineseStrings.strings
        case .english:
            localizedStrings = EnglishStrings.strings
        }
    }
    
    // 获取本地化字符串
    func localizedString(for key: String) -> String {
        return localizedStrings[key] ?? key
    }
    
    // 切换语言
    func switchLanguage(to language: AppLanguage) {
        self.currentLanguage = language
    }
}

// 通知名称扩展
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// 字符串本地化扩展
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}

// 视图扩展，用于响应语言变化
extension View {
    func onLanguageChange(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            action()
        }
    }
}