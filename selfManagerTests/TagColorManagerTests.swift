//
//  TagColorManagerTests.swift
//  selfManagerTests
//
//  Created by AI Assistant on 2025/09/30.
//

import Testing
import SwiftUI
@testable import selfManager

struct TagColorManagerTests {
    @Test func testDeterministicDefaultColorSameAcrossCalls() async throws {
        let manager = TagColorManager.shared
        // 使用一个不存在的标签以触发默认颜色映射
        let tag = "未设置颜色的标签"
        let c1 = manager.getColor(for: tag)
        let c2 = manager.getColor(for: tag)
        // 同一标签多次获取应一致
        #expect(c1.toHex() == c2.toHex())
    }

    @Test func testNormalizationConsistency() async throws {
        let manager = TagColorManager.shared
        // 英文标签用于测试大小写与空白规范化
        let original = "Swift"
        let lowercased = "swift"
        let spaced = "  Swift  "
        let c1 = manager.getColor(for: original)
        let c2 = manager.getColor(for: lowercased)
        let c3 = manager.getColor(for: spaced)
        #expect(c1.toHex() == c2.toHex())
        #expect(c1.toHex() == c3.toHex())
    }

    @Test func testSetColorPersistsAndRespectsNormalization() async throws {
        let manager = TagColorManager.shared
        let tag = "一致性测试标签"
        let normalizedVariant = "  一致性测试标签  "
        let customColor = Color.orange
        // 设置颜色
        manager.setColor(customColor, for: tag)
        // 两种写法都应返回设置的颜色
        let c1 = manager.getColor(for: tag)
        let c2 = manager.getColor(for: normalizedVariant)
        #expect(c1.toHex() == customColor.toHex())
        #expect(c2.toHex() == customColor.toHex())
        // 清理，避免污染其他测试
        manager.removeColor(for: tag)
    }
}