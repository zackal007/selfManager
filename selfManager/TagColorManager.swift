//
//  TagColorManager.swift
//  selfManager
//
//  Created by Trae AI on 2024/12/31.
//

import SwiftUI
import SwiftData
import Combine

// 标签颜色管理器
class TagColorManager: ObservableObject {
    // 单例模式
    static let shared = TagColorManager()
    
    // 用户默认值键
    private let tagColorsKey = "tagColors"
    
    // 标签颜色字典 - 使用@Published实现即时更新
    @Published private var tagColors: [String: String] = [:]
    
    // 颜色更新通知 - 用于触发界面刷新
    @Published var colorUpdateTrigger: UUID = UUID()
    
    // 可用的颜色选项
    let availableColors: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .mint, .cyan, .red
    ]
    
    // 初始化方法
    private init() {
        loadTagColors()
    }
    
    // 加载标签颜色
    private func loadTagColors() {
        if let data = UserDefaults.standard.data(forKey: tagColorsKey),
           let colors = try? JSONDecoder().decode([String: String].self, from: data) {
            tagColors = colors
        }
    }
    
    // 保存标签颜色
    private func saveTagColors() {
        if let data = try? JSONEncoder().encode(tagColors) {
            UserDefaults.standard.set(data, forKey: tagColorsKey)
        }
    }
    
    // 获取标签颜色
    func getColor(for tag: String) -> Color {
        if let colorString = tagColors[tag], let color = Color(hex: colorString) {
            return color
        }
        return defaultColor(for: tag)
    }
    
    // 设置标签颜色
    func setColor(_ color: Color, for tag: String) {
        tagColors[tag] = color.toHex()
        saveTagColors()
        // 触发颜色更新通知
        DispatchQueue.main.async {
            self.colorUpdateTrigger = UUID()
        }
    }
    
    // 更新标签名称
    func updateTagName(from oldTag: String, to newTag: String) {
        if let colorString = tagColors[oldTag] {
            tagColors[newTag] = colorString
            tagColors.removeValue(forKey: oldTag)
            saveTagColors()
            // 触发颜色更新通知
            DispatchQueue.main.async {
                self.colorUpdateTrigger = UUID()
            }
        }
    }
    
    // 删除标签颜色
    func removeColor(for tag: String) {
        tagColors.removeValue(forKey: tag)
        saveTagColors()
        // 触发颜色更新通知
        DispatchQueue.main.async {
            self.colorUpdateTrigger = UUID()
        }
    }
    
    // 强制刷新标签颜色
    func refreshColor(for tag: String) {
        // 如果标签已有颜色，先获取当前颜色
        if let colorString = tagColors[tag], let color = Color(hex: colorString) {
            // 重新设置相同的颜色，触发通知机制
            setColor(color, for: tag)
        } else {
            // 如果没有颜色，使用默认颜色并保存
            let color = defaultColor(for: tag)
            setColor(color, for: tag)
        }
        // 强制保存以确保更新
        saveTagColors()
        // 触发颜色更新通知
        DispatchQueue.main.async {
            self.colorUpdateTrigger = UUID()
        }
    }
    
    // 默认颜色生成
    private func defaultColor(for tag: String) -> Color {
        let index = abs(tag.hashValue) % availableColors.count
        return availableColors[index]
    }
}

// Color扩展，用于颜色与十六进制字符串的转换
extension Color {
    // 从十六进制字符串初始化颜色
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    // 将颜色转换为十六进制字符串
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}