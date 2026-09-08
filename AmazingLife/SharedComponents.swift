//
//  SharedComponents.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import UIKit

// 添加支持从屏幕左边缘向右滑动返回上一页的功能
extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // 确保导航控制器的交互式弹出手势可用
        interactivePopGestureRecognizer?.delegate = nil
        interactivePopGestureRecognizer?.isEnabled = true
    }
}

// SwiftUI修饰符，用于启用滑动返回手势
struct EnableSwipeBackGesture: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 查找并配置所有UINavigationController实例
                // 使用兼容iOS 15+的方式获取窗口
                if #available(iOS 15.0, *) {
                    let scenes = UIApplication.shared.connectedScenes
                    let windowScenes = scenes.compactMap { $0 as? UIWindowScene }
                    windowScenes.forEach { scene in
                        scene.windows.forEach { window in
                            window.rootViewController?.enableSwipeBackGesture()
                        }
                    }
                } else {
                    // 兼容iOS 14及以下版本
                    UIApplication.shared.windows.forEach { window in
                        window.rootViewController?.enableSwipeBackGesture()
                    }
                }
            }
    }
}

// 为View添加启用滑动返回手势的修饰符
extension View {
    func enableSwipeBackGesture() -> some View {
        self.modifier(EnableSwipeBackGesture())
    }
}

// 筛选器芯片组件 - 用于各种筛选器UI
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? (color ?? Color(UIColor.systemBlue)) : Color(UIColor.label))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected
                              ? (color ?? Color(UIColor.systemBlue)).opacity(0.15)
                              : Color(UIColor.systemGray6))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 为UIViewController添加递归启用滑动返回手势的方法
extension UIViewController {
    func enableSwipeBackGesture() {
        if let navigationController = self as? UINavigationController {
            navigationController.interactivePopGestureRecognizer?.delegate = nil
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        // 递归处理子视图控制器
        for child in children {
            child.enableSwipeBackGesture()
        }
        
        // 处理presented视图控制器
        if let presented = presentedViewController {
            presented.enableSwipeBackGesture()
        }
    }
}

// 自定义按钮样式，添加缩放效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(UIAccessibility.isReduceMotionEnabled ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ImageUtility {
    static func saveImageToAppDirectory(image: UIImage, fileName: String) -> URL? {
        guard let data = image.pngData() else { return nil }
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    static func loadImageFromAppDirectory(fileName: String) -> UIImage? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        } else {
            print("File not found at path: \(fileURL.path)")
            return nil
        }
    }
}

// 菜单按钮组件
struct MenuButton<Content: View>: View {
    let content: () -> Content
    @State private var showMenu = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Menu {
            content()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray5).opacity(0.8))
                    .frame(width: 34, height: 34)
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}