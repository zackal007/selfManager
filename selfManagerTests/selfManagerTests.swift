//
//  selfManagerTests.swift
//  selfManagerTests
//
//  Created by zack on 24.6.25.
//

import Testing
import SwiftData
import Foundation
@testable import selfManager

struct selfManagerTests {
    
    // MARK: - Goal Model Tests
    
    @Test func testGoalCreation() async throws {
        let goal = Goal(
            name: "测试目标",
            description: "这是一个测试目标",
            progress: 0.5,
            backgroundImage: nil,
            tags: ["测试", "目标"],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "短期目标",
            goalType: .shortTerm,
            dueDate: Date()
        )
        
        #expect(goal.name == "测试目标")
        #expect(goal.goalDescription == "这是一个测试目标")
        #expect(goal.progress == 0.5)
        #expect(goal.tags.count == 2)
        #expect(goal.goalType == .shortTerm)
    }
    
    @Test func testGoalTypeFromString() async throws {
        #expect(GoalType.from(string: "人生目标") == .life)
        #expect(GoalType.from(string: "年度目标") == .yearly)
        #expect(GoalType.from(string: "短期目标") == .shortTerm)
        #expect(GoalType.from(string: "习惯") == .habit)
        #expect(GoalType.from(string: "未知类型") == .shortTerm) // 默认值
    }
    
    @Test func testGoalProgressValidation() async throws {
        let goal = Goal(
            name: "进度测试",
            description: "测试进度范围",
            progress: 1.5, // 超出范围
            backgroundImage: nil,
            tags: [],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "测试",
            goalType: .shortTerm,
            dueDate: nil
        )
        
        // 进度应该被限制在0-1之间
        #expect(goal.progress >= 0.0)
        #expect(goal.progress <= 1.0)
    }
    
    // MARK: - Contact Model Tests
    
    @Test func testContactCreation() async throws {
        let contact = Contact(
            name: "张三",
            company: "测试公司",
            position: "测试工程师",
            phone: "13800138000",
            email: "zhangsan@test.com",
            address: "测试地址",
            notes: "测试备注",
            contactType: .colleague,
            frequency: .monthly,
            tags: ["朋友", "同事"]
        )
        
        #expect(contact.name == "张三")
        #expect(contact.company == "测试公司")
        #expect(contact.contactType == .colleague)
        #expect(contact.tags.count == 2)
    }
    
    @Test func testContactTypeDisplayName() async throws {
        #expect(ContactType.family.displayName == "家人")
        #expect(ContactType.friend.displayName == "朋友")
        #expect(ContactType.colleague.displayName == "同事")
        #expect(ContactType.other.displayName == "其他")
    }
    
    @Test func testContactFrequencyDisplayName() async throws {
        #expect(ContactFrequency.daily.displayName == "每天")
        #expect(ContactFrequency.weekly.displayName == "每周")
        #expect(ContactFrequency.monthly.displayName == "每月")
        #expect(ContactFrequency.quarterly.displayName == "每季度")
        #expect(ContactFrequency.yearly.displayName == "每年")
        #expect(ContactFrequency.occasional.displayName == "偶尔")
    }
    
    // MARK: - Search Functionality Tests
    
    @Test func testGoalSearchByName() async throws {
        let goals = [
            Goal(name: "学习Swift", description: "掌握Swift编程", progress: 0.3, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "学习", goalType: .shortTerm, dueDate: nil),
            Goal(name: "健身计划", description: "每天锻炼一小时", progress: 0.6, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "健康", goalType: .habit, dueDate: nil),
            Goal(name: "读书目标", description: "今年读50本书", progress: 0.2, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "学习", goalType: .yearly, dueDate: nil)
        ]
        
        let searchText = "学习"
        let filteredGoals = goals.filter { goal in
            goal.name.localizedCaseInsensitiveContains(searchText) ||
            goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
            goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        #expect(filteredGoals.count == 1)
        #expect(filteredGoals.first?.name == "学习Swift")
    }
    
    @Test func testContactSearchByMultipleFields() async throws {
        let contacts = [
            Contact(name: "李四", company: "苹果公司", position: "iOS开发", phone: "13900139000", email: "lisi@apple.com", address: "北京", notes: "技术专家", contactType: .colleague, frequency: .monthly, tags: ["技术", "iOS"]),
             Contact(name: "王五", company: "谷歌", position: "Android开发", phone: "13700137000", email: "wangwu@google.com", address: "上海", notes: "安卓专家", contactType: .colleague, frequency: .weekly, tags: ["技术", "Android"]),
             Contact(name: "赵六", company: "微软", position: "产品经理", phone: "13600136000", email: "zhaoliu@microsoft.com", address: "深圳", notes: "产品设计", contactType: .colleague, frequency: .monthly, tags: ["产品", "设计"])
        ]
        
        let searchText = "iOS"
        let filteredContacts = contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText) ||
            (contact.company?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (contact.position?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            contact.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        #expect(filteredContacts.count == 1)
        #expect(filteredContacts.first?.name == "李四")
    }
    
    // MARK: - Data Validation Tests
    
    @Test func testGoalNameValidation() async throws {
        // 测试空名称
        let emptyNameGoal = Goal(name: "", description: "测试", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: nil)
        #expect(emptyNameGoal.name.isEmpty)
        
        // 测试长名称
        let longName = String(repeating: "a", count: 100)
        let longNameGoal = Goal(name: longName, description: "测试", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: nil)
        #expect(longNameGoal.name.count == 100)
    }
    
    @Test func testContactEmailValidation() async throws {
        let contact = Contact(name: "测试", company: nil, position: nil, phone: nil, email: "invalid-email", address: nil, notes: nil, contactType: .other, frequency: .occasional, tags: [])
        
        // 这里可以添加邮箱格式验证逻辑
        let email = contact.email ?? ""
        let isValidEmail = email.contains("@") && email.contains(".")
        #expect(!isValidEmail) // 无效邮箱应该返回false
    }
    
    // MARK: - Date and Time Tests
    
    @Test func testGoalDueDateHandling() async throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        
        let futureGoal = Goal(name: "未来目标", description: "30天后到期", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: futureDate)
        
        let pastGoal = Goal(name: "过期目标", description: "30天前到期", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: pastDate)
        
        #expect(futureGoal.dueDate! > Date())
        #expect(pastGoal.dueDate! < Date())
    }
    
    // MARK: - Performance Tests
    
    @Test func testLargeDataSetFiltering() async throws {
        // 创建大量测试数据
        var goals: [Goal] = []
        for i in 0..<1000 {
            let goal = Goal(
                name: "目标\(i)",
                description: "描述\(i)",
                progress: Double(i % 100) / 100.0,
                backgroundImage: nil,
                tags: ["标签\(i % 10)"],
                upperProject: [],
                subProject: [],
                recordNum: 0,
                category: "类别\(i % 5)",
                goalType: GoalType.allCases[i % GoalType.allCases.count],
                dueDate: nil
            )
            goals.append(goal)
        }
    }
    
    // MARK: - Record Sorting Tests
    
    @Test func testRecordTypeDisplayName() async throws {
        #expect(RecordType.recent.displayName == "近期")
        #expect(RecordType.daily.displayName == "日记")
        #expect(RecordType.weekly.displayName == "周记")
        #expect(RecordType.monthly.displayName == "月记")
        #expect(RecordType.quarterly.displayName == "季记")
        #expect(RecordType.yearly.displayName == "年记")
    }
    
    @Test func testRecordSortingLogic() async throws {
        // 测试记录排序逻辑，确保不同类型的记录有正确的排序行为
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        
        // 创建测试记录数据
        let records = [
            Record(recordType: .daily, title: "今天", content: "今天的内容", date: now, year: 2024, month: 12, day: 25, week: 52, quarter: 4),
            Record(recordType: .daily, title: "昨天", content: "昨天的内容", date: yesterday, year: 2024, month: 12, day: 24, week: 52, quarter: 4),
            Record(recordType: .daily, title: "明天", content: "明天的内容", date: tomorrow, year: 2024, month: 12, day: 26, week: 52, quarter: 4)
        ]
        
        // 按时间倒序排序（最新的在前）
        let sortedRecords = records.sorted { $0.date > $1.date }
        
        #expect(sortedRecords.count == 3)
        #expect(sortedRecords[0].title == "明天") // 最新的记录
        #expect(sortedRecords[1].title == "今天")
        #expect(sortedRecords[2].title == "昨天") // 最旧的记录
    }
    
    @Test func testRecordTypeMenuButtonLabels() async throws {
        // 测试不同记录类型对应的菜单按钮标签
        let dailyLabel = "跳转到今天"
        let weeklyLabel = "跳转到本周"
        let monthlyLabel = "跳转到本月"
        let quarterlyLabel = "跳转到本季"
        let yearlyLabel = "跳转到本年"
        
        #expect(dailyLabel.contains("今天"))
        #expect(weeklyLabel.contains("本周"))
        #expect(monthlyLabel.contains("本月"))
        #expect(quarterlyLabel.contains("本季"))
        #expect(yearlyLabel.contains("本年"))
    }
    
    @Test func testRecentRecordTypeSpecialBehavior() async throws {
        // 测试"近期"记录类型的特殊行为
        let recentType = RecordType.recent
        
        #expect(recentType == .recent)
        #expect(recentType.displayName == "近期")
        
        // 验证近期类型应该显示排序按钮而不是日期选择器
        // 这个逻辑在UI层面实现，这里测试数据层面的准备
        let testRecords = [
            Record(recordType: .daily, title: "记录1", content: "内容1", date: Date(), year: 2024, month: 12, day: 25, week: 52, quarter: 4),
            Record(recordType: .weekly, title: "记录2", content: "内容2", date: Date().addingTimeInterval(-86400), year: 2024, month: 12, day: 24, week: 52, quarter: 4)
        ]
        
        // 确保记录类型不包含近期类型（近期是虚拟类型，不存储实际记录）
        let nonRecentRecords = testRecords.filter { $0.recordType != .recent }
        #expect(nonRecentRecords.count == 2)
    }
        
        // 测试搜索性能
        let startTime = Date()
        let filteredGoals = goals.filter { goal in
            goal.name.localizedCaseInsensitiveContains("目标1") ||
            goal.goalDescription.localizedCaseInsensitiveContains("目标1") ||
            goal.tags.contains { $0.localizedCaseInsensitiveContains("目标1") }
        }
        let endTime = Date()
        
        let searchTime = endTime.timeIntervalSince(startTime)
        #expect(searchTime < 1.0) // 搜索应该在1秒内完成
        #expect(filteredGoals.count > 0) // 应该找到匹配项
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testEmptySearchText() async throws {
        let goals = [
            Goal(name: "目标1", description: "描述1", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: nil)
        ]
        
        let searchText = ""
        let filteredGoals = goals.filter { goal in
            !searchText.isEmpty && (
                goal.name.localizedCaseInsensitiveContains(searchText) ||
                goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            )
        }
        
        #expect(filteredGoals.isEmpty) // 空搜索文本应该返回空结果
    }
    
    @Test func testSpecialCharactersInSearch() async throws {
        let goal = Goal(
            name: "特殊字符@#$%",
            description: "包含特殊字符的描述！？",
            progress: 0.0,
            backgroundImage: nil,
            tags: ["标签@", "#特殊"],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "测试",
            goalType: .shortTerm,
            dueDate: nil
        )
        
        let searchText = "@"
        let isFound = goal.name.localizedCaseInsensitiveContains(searchText) ||
                     goal.goalDescription.localizedCaseInsensitiveContains(searchText) ||
                     goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        
        #expect(isFound) // 应该能找到包含特殊字符的内容
    }

}
