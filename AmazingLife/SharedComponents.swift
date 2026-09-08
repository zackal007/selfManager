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
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("双击切换筛选状态")
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
// Apple 原则：按钮反馈应在 pointer-down 时即时响应，使用短时 easeOut 而非 spring
struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
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

// MARK: - Design Tokens
struct DesignToken {
    // MARK: - Corner Radius
    /// Primary corner radius for cards and containers (16pt)
    static let cornerRadius: CGFloat = 16
    /// Medium corner radius for input fields and medium elements (12pt)
    static let cornerRadiusMedium: CGFloat = 12
    /// Secondary corner radius for smaller elements (10pt)
    static let cornerRadiusSmall: CGFloat = 10
    /// Tertiary corner radius for chips and tags (8pt)
    static let cornerRadiusTertiary: CGFloat = 8
    /// Small corner radius for badges and small indicators (4pt)
    static let cornerRadiusBadge: CGFloat = 4
    /// Editor corner radius for text input areas (6pt)
    static let cornerRadiusEditor: CGFloat = 6
    /// Large corner radius for special cards and overlays (20pt)
    static let cornerRadiusLarge: CGFloat = 20

    // MARK: - Spacing (4pt Grid)
    static let spacing1: CGFloat = 4
    static let spacing2: CGFloat = 8
    static let spacing3: CGFloat = 12
    static let spacing4: CGFloat = 16
    static let spacing5: CGFloat = 20
    static let spacing6: CGFloat = 24
    static let spacing8: CGFloat = 32

    // MARK: - Shadows
    /// Card shadow color that adapts to dark mode
    static let cardShadowColor = AppColors.cardShadow
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 4

    /// Elevated shadow for floating elements
    static let elevatedShadowColor = AppColors.elevatedShadow
    static let elevatedShadowRadius: CGFloat = 12
    static let elevatedShadowY: CGFloat = 6

    /// Dragging shadow for card lift effect
    static let cardShadowDragging = AppColors.elevatedShadow
    static let cardShadowDraggingRadius: CGFloat = 12
    static let cardShadowDraggingY: CGFloat = 8

    // MARK: - Typography (uses system Dynamic Type)
    /// Large title - display text
    static let fontLargeTitle = Font.largeTitle
    /// Title - section headers
    static let fontTitle = Font.title
    /// Title 2 - subsection headers
    static let fontTitle2 = Font.title2
    /// Title 3 - smaller headers
    static let fontTitle3 = Font.title3
    /// Headline - emphasized text
    static let fontHeadline = Font.headline
    /// Body - default text
    static let fontBody = Font.body
    /// Callout - secondary text
    static let fontCallout = Font.callout
    /// Subheadline - tertiary text
    static let fontSubheadline = Font.subheadline
    /// Footnote - small text
    static let fontFootnote = Font.footnote
    /// Caption - smallest text
    static let fontCaption = Font.caption
    /// Caption 2 - tiny text
    static let fontCaption2 = Font.caption2
}

// MARK: - App Colors
struct AppColors {
    // Primary
    static let primary = Color(UIColor.systemBlue)

    // Semantic
    static let success = Color(UIColor.systemGreen)
    static let warning = Color(UIColor.systemOrange)
    static let error = Color(UIColor.systemRed)

    // Text
    static let text = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // Backgrounds
    static let background = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemGroupedBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemGroupedBackground)

    // Fills
    static let fill = Color(UIColor.systemGray5)
    static let fillSecondary = Color(UIColor.systemGray6)

    // Overlays & Scrims (adaptive for dark/light mode)
    /// Heavy scrim for modals and destructive overlays
    static let scrimHeavy = Color.black.opacity(0.5)
    /// Light scrim for subtle overlays
    static let scrimLight = Color.black.opacity(0.2)
    /// Card shadow color that adapts to dark mode
    static let cardShadow = Color(UIColor.label).opacity(0.08)
    /// Elevated shadow for floating elements
    static let elevatedShadow = Color(UIColor.label).opacity(0.12)
    /// Separator color for dividers
    static let separator = Color(UIColor.separator)
}

// MARK: - Color Scheme Adaptive Colors
extension Color {
    /// Creates a color that adapts to light/dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                if let cgColor = dark.cgColor {
                    return UIColor(cgColor: cgColor)
                }
                return UIColor.darkGray
            default:
                if let cgColor = light.cgColor {
                    return UIColor(cgColor: cgColor)
                }
                return UIColor.lightGray
            }
        })
    }
}

// MARK: - Rubber Band Effect
/// Apple 风格的橡皮筋效果 — 边界处渐进阻力而非硬停止
/// - Parameters:
///   - overshoot: 超出边界的距离
///   - dimension: 可用维度（宽度或高度）
///   - constant: 阻力常数，默认 0.55
/// - Returns: 衰减后的偏移量
func rubberband(overshoot: CGFloat, dimension: CGFloat, constant: CGFloat = 0.55) -> CGFloat {
    return (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
}

/// 对 CGSize 应用橡皮筋效果（用于拖拽边界）
func rubberbandOffset(_ offset: CGSize, bounds: CGSize) -> CGSize {
    let dampedX = offset.width > 0 ? rubberband(overshoot: offset.width, dimension: bounds.width)
                                    : -rubberband(overshoot: -offset.width, dimension: bounds.width)
    let dampedY = offset.height > 0 ? rubberband(overshoot: offset.height, dimension: bounds.height)
                                    : -rubberband(overshoot: -offset.height, dimension: bounds.height)
    return CGSize(width: dampedX, height: dampedY)
}

// MARK: - App Spring Animations
extension Animation {
    /// Default UI animation - critically damped, no overshoot
    static let appSnappy = Animation.spring(response: 0.3, dampingFraction: 1.0)

    /// Bouncy animation for drag release with momentum
    static let appBouncy = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Gesture tracking animation
    static let appGesture = Animation.spring(response: 0.28, dampingFraction: 0.9)

    /// Sidebar animation
    static let appSidebar = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Card appear/disappear animation - gentle and non-distracting
    static let cardAppear = Animation.spring(response: 0.35, dampingFraction: 0.85)

    /// Sheet/drawer present animation - slightly bouncy for momentum feel
    static let sheetPresent = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Fade in animation for content appearing
    static let fadeIn = Animation.easeOut(duration: 0.2)

    /// Fade out animation for content disappearing
    static let fadeOut = Animation.easeIn(duration: 0.15)

    /// Scale appear animation for popups/tooltips
    static let scaleAppear = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Press feedback animation - quick and snappy
    static let pressFeedback = Animation.spring(response: 0.15, dampingFraction: 0.9)

    /// Tab switch animation
    static let tabSwitch = Animation.spring(response: 0.2, dampingFraction: 0.85)
}

// MARK: - Reduced Motion & Transparency Support
extension View {
    /// Apply animation that respects reduced motion settings
    @ViewBuilder
    func appAnimation<S: ShapeStyle>(_ animation: Animation?) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self.animation(nil, value: animation == nil)
        } else {
            self.animation(animation, value: animation == nil)
        }
    }

    /// Apply spring animation that respects reduced motion
    @ViewBuilder
    func appSpringAnimation(_ animation: Animation?) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            // Use a simple opacity transition instead of spring
            self.transition(.opacity)
        } else {
            self.animation(animation, value: animation == nil)
        }
    }

    /// Apply backdrop blur that respects reduced transparency settings
    @ViewBuilder
    func adaptiveBackdrop(_ isBlurred: Bool = true) -> some View {
        if isBlurred {
            if UIAccessibility.isReduceTransparencyEnabled {
                self.background(Color(UIColor.systemBackground))
            } else {
                self.background(.ultraThinMaterial)
            }
        } else {
            self
        }
    }
}

// MARK: - Card Shadow Modifier
extension View {
    /// Apply standard card shadow
    func cardShadow() -> some View {
        self.shadow(
            color: DesignToken.cardShadowColor,
            radius: DesignToken.cardShadowRadius,
            x: 0,
            y: DesignToken.cardShadowY
        )
    }

    /// Apply elevated card shadow
    func elevatedShadow() -> some View {
        self.shadow(
            color: DesignToken.elevatedShadowColor,
            radius: DesignToken.elevatedShadowRadius,
            x: 0,
            y: DesignToken.elevatedShadowY
        )
    }
}

// MARK: - Card Style Modifier
extension View {
    /// Apply standard card styling with unified corner radius and shadow
    func cardStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: DesignToken.cornerRadius))
            .cardShadow()
    }

    /// Apply small card styling
    func cardStyleSmall() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: DesignToken.cornerRadiusSmall))
            .cardShadow()
    }

    /// Apply standard sheet style with detents for iPad compatibility
    func standardSheetStyle() -> some View {
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }
}

// MARK: - Illustrated Empty State
/// An illustrated empty state view with SF Symbol icon, title, subtitle, and optional action button
struct IllustratedEmptyState: View {
    let icon: String           // SF Symbol name
    let title: String          // Main message
    let subtitle: String?      // Optional secondary message
    var actionTitle: String?   // Optional action button title
    var action: (() -> Void)? // Optional action handler
    var tintColor: Color = .blue  // Semantic color for icon

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Icon container with subtle background
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(iconColor)
            }

            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var iconBackgroundColor: Color {
        colorScheme == .dark
            ? tintColor.opacity(0.15)
            : tintColor.opacity(0.08)
    }

    private var iconColor: Color {
        colorScheme == .dark
            ? tintColor.opacity(0.85)
            : tintColor.opacity(0.7)
    }
}

// MARK: - Predefined Empty States
extension IllustratedEmptyState {
    /// Empty state for contacts screen - uses blue for person/network theme
    static func contacts(action: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            icon: "person.crop.circle.badge.plus",
            title: "empty_no_contacts".localized,
            subtitle: "add_first_contact_subtitle".localized,
            actionTitle: "add_first_contact".localized,
            action: action,
            tintColor: .blue
        )
    }

    /// Empty state for goals screen - uses green for achievement/target theme
    static func goals(action: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            icon: "target",
            title: "empty_no_goals".localized,
            subtitle: "add_first_goal_subtitle".localized,
            actionTitle: "add_first_goal".localized,
            action: action,
            tintColor: .green
        )
    }

    /// Empty state for records screen - uses orange for writing/document theme
    static func records(action: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            icon: "square.and.pencil",
            title: "no_records_recent".localized,
            subtitle: "start_first_record".localized,
            actionTitle: "create_record".localized,
            action: action,
            tintColor: .orange
        )
    }

    /// Empty state for search with no results - uses gray
    static func noSearchResults(for query: String) -> IllustratedEmptyState {
        IllustratedEmptyState(
            icon: "magnifyingglass",
            title: "no_results_found".localized,
            subtitle: String(format: "try_different_search".localized, query),
            tintColor: Color(UIColor.systemGray)
        )
    }
}

// MARK: - Menu Button Component
struct MenuButton<Content: View>: View {
    let content: () -> Content
    @State private var showMenu = false
    var accessibilityLabel: String = "更多选项"

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
        .accessibilityLabel(accessibilityLabel)
    }
}