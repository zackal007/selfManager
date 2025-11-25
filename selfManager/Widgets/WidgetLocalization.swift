import Foundation

struct WidgetLocalization {
    static func localized(_ key: String) -> String {
        let code = Locale.current.languageCode?.lowercased() ?? "en"
        let isChinese = code.hasPrefix("zh")
        switch key {
        case "goals":
            return isChinese ? "置顶目标" : "Pinned Goals"
        case "contacts":
            return isChinese ? "置顶人脉" : "Pinned Contacts"
        default:
            return key
        }
    }
}
