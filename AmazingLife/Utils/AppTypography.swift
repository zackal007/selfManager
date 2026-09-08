import SwiftUI
import UIKit

struct AppFont {
    private static func scaled(_ base: CGFloat, _ style: UIFont.TextStyle) -> CGFloat {
        UIFontMetrics(forTextStyle: style).scaledValue(for: base)
    }

    // 创建带 kerning 的字体
    private static func kernedFont(size: CGFloat, weight: UIFont.Weight = .regular, kerning: CGFloat) -> Font {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = font.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: "kern"): NSNumber(value: kerning)
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }

    static func navTitle() -> Font { kernedFont(size: scaled(24, .title1), weight: .bold, kerning: -0.5) }
    static func pageTitle() -> Font { .system(size: scaled(22, .title2), weight: .bold) }
    static func sectionTitle() -> Font { .system(size: scaled(18, .headline), weight: .semibold) }
    static func body() -> Font { .system(size: scaled(16, .body)) }
    static func bodyMedium() -> Font { .system(size: scaled(16, .body), weight: .medium) }
    static func subtext() -> Font { .system(size: scaled(14, .subheadline)) }
    static func subtextMedium() -> Font { .system(size: scaled(14, .subheadline), weight: .medium) }
    static func caption() -> Font { kernedFont(size: scaled(13, .caption1), kerning: 0.2) }
    static func captionMedium() -> Font { .system(size: scaled(13, .caption1), weight: .medium) }
    static func assist() -> Font { .system(size: scaled(12, .caption2)) }
    static func assistMedium() -> Font { .system(size: scaled(12, .caption2), weight: .medium) }
    static func badge() -> Font { .system(size: scaled(11, .caption2), weight: .bold) }
    static func hero() -> Font { kernedFont(size: scaled(32, .title1), weight: .medium, kerning: -0.3) }
    static func navBack() -> Font { .system(size: scaled(17, .headline), weight: .medium) }
}