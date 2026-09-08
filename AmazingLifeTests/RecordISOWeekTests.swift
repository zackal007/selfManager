//
//  RecordISOWeekTests.swift
//  AmazingLifeTests
//
//  Validates ISO 8601 week number and year boundaries across year end.
//

import Testing
import Foundation
@testable import AmazingLife

struct RecordISOWeekTests {
    // 构造指定时区的日期（中午避免潜在跨日误差）
    private func date(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps)!
    }

    @Test func testISOWeekBoundariesAcrossTimeZones() async throws {
        let timeZones: [TimeZone] = [
            TimeZone(secondsFromGMT: 0)!,
            TimeZone(identifier: "Asia/Shanghai")!,
            TimeZone(identifier: "America/Los_Angeles")!,
            TimeZone(identifier: "Europe/London")!
        ]
        
        for tz in timeZones {
            // 2024-12-28（周六）与 2024-12-29（周日）应为 2024 年第 52 周
            let d1 = date(year: 2024, month: 12, day: 28, timeZone: tz)
            let d2 = date(year: 2024, month: 12, day: 29, timeZone: tz)
            #expect(RecordCardView.isoWeekDisplay(for: d1, timeZone: tz) == "2024年第52周")
            #expect(RecordCardView.isoWeekDisplay(for: d2, timeZone: tz) == "2024年第52周")

            // 2024-12-30（周一）到 2025-01-04（周六）应为 2025 年第 1 周
            let d3 = date(year: 2024, month: 12, day: 30, timeZone: tz)
            let d4 = date(year: 2024, month: 12, day: 31, timeZone: tz)
            let d5 = date(year: 2025, month: 1, day: 1, timeZone: tz)
            let d6 = date(year: 2025, month: 1, day: 2, timeZone: tz)
            let d7 = date(year: 2025, month: 1, day: 3, timeZone: tz)
            let d8 = date(year: 2025, month: 1, day: 4, timeZone: tz)
            #expect(RecordCardView.isoWeekDisplay(for: d3, timeZone: tz) == "2025年第1周")
            #expect(RecordCardView.isoWeekDisplay(for: d4, timeZone: tz) == "2025年第1周")
            #expect(RecordCardView.isoWeekDisplay(for: d5, timeZone: tz) == "2025年第1周")
            #expect(RecordCardView.isoWeekDisplay(for: d6, timeZone: tz) == "2025年第1周")
            #expect(RecordCardView.isoWeekDisplay(for: d7, timeZone: tz) == "2025年第1周")
            #expect(RecordCardView.isoWeekDisplay(for: d8, timeZone: tz) == "2025年第1周")

            // 一致性检查：2024-12-31 与 2025-01-01 必须一致
            #expect(RecordCardView.isoWeekDisplay(for: d4, timeZone: tz) == RecordCardView.isoWeekDisplay(for: d5, timeZone: tz))
        }
    }
}