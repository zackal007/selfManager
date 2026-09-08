//
//  SystemTypography.swift
//  selfManager
//
//  Created by Assistant on 2025/01/08.
//

import SwiftUI
import UIKit

// 全局系统字体修饰符：让未显式指定字体的文本默认使用系统的动态字体
struct GlobalTypography: ViewModifier {
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        // 使用系统动态字体的正文作为默认字体，自动适配系统字体家族与大小
        // 不强制设置字体粗细，避免覆盖局部强调；粗体辅助通过 legibilityWeight 环境自动生效
        content
            .font(Font(UIFont.preferredFont(forTextStyle: .body)))
    }
}

extension View {
    // 应用全局系统字体修饰符
    func useGlobalSystemTypography() -> some View {
        self.modifier(GlobalTypography())
    }

    // 按系统TextStyle获取并应用动态系统字体，确保与系统设置一致
    func applySystemFont(_ style: UIFont.TextStyle) -> some View {
        self.font(Font(UIFont.preferredFont(forTextStyle: style)))
    }

    // 根据系统的可读性权重（无障碍“粗体文本”）自动增强粗细；
    // 默认不改变现有粗细，仅在系统要求粗体时提升到 .bold
    func applySystemLegibilityWeight() -> some View {
        modifier(SystemLegibilityWeight())
    }
}

// 内部修饰符：根据环境 legibilityWeight 自动提升字体粗细
private struct SystemLegibilityWeight: ViewModifier {
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        switch legibilityWeight {
        case .bold:
            return AnyView(content.fontWeight(.bold))
        default:
            return AnyView(content)
        }
    }
}