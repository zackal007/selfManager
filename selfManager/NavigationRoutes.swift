import SwiftUI

// 全局路由类型，用于跨页面的 push 导航
enum AppRoute: Hashable {
    case tags
    case settings
    case assets
    case profile
    case achievements
    case anxieties
    case userEdit
    case tagDetail(String)
}