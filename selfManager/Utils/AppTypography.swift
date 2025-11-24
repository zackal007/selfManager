import SwiftUI
import UIKit

struct AppFont {
    private static func scaled(_ base: CGFloat, _ style: UIFont.TextStyle) -> CGFloat {
        UIFontMetrics(forTextStyle: style).scaledValue(for: base)
    }

    static func navTitle() -> Font { .system(size: scaled(24, .title1), weight: .bold) }
    static func pageTitle() -> Font { .system(size: scaled(22, .title2), weight: .bold) }
    static func sectionTitle() -> Font { .system(size: scaled(18, .headline), weight: .semibold) }
    static func body() -> Font { .system(size: scaled(16, .body)) }
    static func bodyMedium() -> Font { .system(size: scaled(16, .body), weight: .medium) }
    static func subtext() -> Font { .system(size: scaled(14, .subheadline)) }
    static func subtextMedium() -> Font { .system(size: scaled(14, .subheadline), weight: .medium) }
    static func caption() -> Font { .system(size: scaled(13, .caption1)) }
    static func captionMedium() -> Font { .system(size: scaled(13, .caption1), weight: .medium) }
    static func assist() -> Font { .system(size: scaled(12, .caption2)) }
    static func assistMedium() -> Font { .system(size: scaled(12, .caption2), weight: .medium) }
    static func badge() -> Font { .system(size: scaled(11, .caption2), weight: .bold) }
    static func hero() -> Font { .system(size: scaled(32, .title1), weight: .medium) }
    static func navBack() -> Font { .system(size: scaled(17, .headline), weight: .medium) }
}