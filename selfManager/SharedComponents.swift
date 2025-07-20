//
//  SharedComponents.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI

// 自定义按钮样式，添加缩放效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}