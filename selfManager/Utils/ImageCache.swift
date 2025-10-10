import Foundation
import UIKit

// 轻量图片缓存与加载工具：优先从资产目录加载，其次从文档目录加载
// 提供同步接口以适配 SwiftUI 小图标使用场景
final class SMImageCache {
    static let shared = SMImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 32 * 1024 * 1024 // 约 32MB
    }

    func image(named name: String) -> UIImage? {
        let key = name as NSString
        if let img = cache.object(forKey: key) { return img }

        // 尝试从资产目录加载
        if let uiImage = UIImage(named: name) {
            cache.setObject(uiImage, forKey: key, cost: uiImage.sm_cost)
            return uiImage
        }

        // 尝试从文档目录加载（用户自定义背景图）
        let fileURL = getDocumentsDirectory().appendingPathComponent(name)
        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
            cache.setObject(uiImage, forKey: key, cost: uiImage.sm_cost)
            return uiImage
        }

        return nil
    }
}

private extension UIImage {
    var sm_cost: Int {
        guard let cg = self.cgImage else { return 0 }
        return cg.bytesPerRow * cg.height
    }
}

// 通用：文档目录获取
func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}