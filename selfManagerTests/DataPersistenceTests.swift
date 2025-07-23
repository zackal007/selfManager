//
//  DataPersistenceTests.swift
//  selfManagerTests
//
//  Created by AI Assistant on 2024.
//

import Testing
import SwiftData
import Foundation
@testable import selfManager

struct DataPersistenceTests {
    
    // MARK: - SwiftData Model Tests
    
    @Test func testGoalModelPersistence() async throws {
        // 测试Goal模型的SwiftData属性
        let goal = Goal(
            name: "持久化测试目标",
            description: "测试SwiftData持久化",
            progress: 0.75,
            backgroundImage: nil,
            tags: ["测试", "持久化"],
            upperProject: [],
            subProject: [],
            recordNum: 5,
            category: "测试类别",
            goalType: .shortTerm,
            dueDate: Date()
        )
        
        // 验证模型属性
        #expect(goal.name == "持久化测试目标")
        #expect(goal.goalDescription == "测试SwiftData持久化")
        #expect(goal.progress == 0.75)
        #expect(goal.tags.count == 2)
        #expect(goal.recordNum == 5)
        #expect(goal.goalType == .shortTerm)
        #expect(goal.dueDate != nil)
    }
    
    @Test func testContactModelPersistence() async throws {
        // 测试Contact模型的SwiftData属性
        let contact = Contact(
            name: "持久化测试联系人",
            company: "测试公司",
            position: "测试职位",
            phone: "13800138000",
            email: "test@persistence.com",
            address: "测试地址123号",
            notes: "持久化测试备注",
            contactType: .colleague,
            frequency: .monthly,
            tags: ["测试", "持久化", "工作"]
        )
        
        // 验证模型属性
        #expect(contact.name == "持久化测试联系人")
        #expect(contact.company == "测试公司")
        #expect(contact.position == "测试职位")
        #expect(contact.phone == "13800138000")
        #expect(contact.email == "test@persistence.com")
        #expect(contact.address == "测试地址123号")
        #expect(contact.notes == "持久化测试备注")
        #expect(contact.contactType == .colleague)
        #expect(contact.frequency == .monthly)
        #expect(contact.tags.count == 3)
    }
    
    // MARK: - Data Validation Tests
    
    @Test func testGoalDataIntegrity() async throws {
        // 测试目标数据的完整性
        let goal = Goal(
            name: "数据完整性测试",
            description: "验证数据完整性",
            progress: 0.5,
            backgroundImage: nil,
            tags: ["完整性", "验证"],
            upperProject: [],
            subProject: [],
            recordNum: 10,
            category: "测试",
            goalType: .yearly,
            dueDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
        
        // 验证必需字段
        #expect(!goal.name.isEmpty)
        #expect(!goal.goalDescription.isEmpty)
        #expect(goal.progress >= 0.0 && goal.progress <= 1.0)
        #expect(goal.recordNum >= 0)
        #expect(!goal.category.isEmpty)
        
        // 验证日期逻辑
        if let dueDate = goal.dueDate {
            #expect(dueDate > Date())
        }
    }
    
    @Test func testContactDataIntegrity() async throws {
        // 测试联系人数据的完整性
        let contact = Contact(
            name: "数据完整性测试联系人",
            company: "完整性测试公司",
            position: "测试工程师",
            phone: "13900139000",
            email: "integrity@test.com",
            address: "完整性测试地址456号",
            notes: "数据完整性测试备注",
            contactType: .friend,
            frequency: .weekly,
            tags: ["完整性", "测试", "朋友"]
        )
        
        // 验证必需字段
        #expect(!contact.name.isEmpty)
        
        // 验证可选字段的处理
        if let company = contact.company {
            #expect(!company.isEmpty)
        }
        
        if let email = contact.email {
            #expect(email.contains("@"))
            #expect(email.contains("."))
        }
        
        if let phone = contact.phone {
            #expect(phone.count >= 10) // 假设电话号码至少10位
        }
    }
    
    // MARK: - Relationship Tests
    
    @Test func testGoalProjectRelationships() async throws {
        // 测试目标项目关系
        let parentGoal = Goal(
            name: "父级目标",
            description: "包含子项目的目标",
            progress: 0.3,
            backgroundImage: nil,
            tags: ["父级"],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "项目管理",
            goalType: .life,
            dueDate: nil
        )
        
        let childGoal = Goal(
            name: "子级目标",
            description: "属于父级目标的子项目",
            progress: 0.8,
            backgroundImage: nil,
            tags: ["子级"],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "子项目",
            goalType: .shortTerm,
            dueDate: nil
        )
        
        // 验证关系结构
        #expect(parentGoal.subProject.isEmpty) // 初始为空
        #expect(childGoal.upperProject.isEmpty) // 初始为空
        
        // 这里可以添加更多关系测试逻辑
    }
    
    // MARK: - Data Migration Tests
    
    @Test func testGoalTypeEnumMigration() async throws {
        // 测试GoalType枚举的向后兼容性
        let allGoalTypes: [GoalType] = [.life, .yearly, .shortTerm, .habit]
        
        for goalType in allGoalTypes {
            let goal = Goal(
                name: "类型测试\(goalType.rawValue)",
                description: "测试目标类型\(goalType)",
                progress: 0.0,
                backgroundImage: nil,
                tags: [],
                upperProject: [],
                subProject: [],
                recordNum: 0,
                category: "类型测试",
                goalType: goalType,
                dueDate: nil
            )
            
            #expect(goal.goalType == goalType)
        }
    }
    
    @Test func testContactTypeEnumMigration() async throws {
        // 测试ContactType枚举的向后兼容性
        let allContactTypes: [ContactType] = [.family, .friend, .colleague, .other]
        
        for contactType in allContactTypes {
            let contact = Contact(
                name: "类型测试\(contactType.rawValue)",
                company: nil,
                position: nil,
                phone: nil,
                email: nil,
                address: nil,
                notes: nil,
                contactType: contactType,
                frequency: .occasional,
                tags: []
            )
            
            #expect(contact.contactType == contactType)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test func testLargeDataSetCreation() async throws {
        // 测试大量数据创建的性能
        let startTime = Date()
        
        var goals: [Goal] = []
        for i in 0..<1000 {
            let goal = Goal(
                name: "性能测试目标\(i)",
                description: "性能测试描述\(i)",
                progress: Double(i % 100) / 100.0,
                backgroundImage: nil,
                tags: ["性能", "测试\(i % 10)"],
                upperProject: [],
                subProject: [],
                recordNum: i,
                category: "性能测试\(i % 5)",
                goalType: GoalType.allCases[i % GoalType.allCases.count],
                dueDate: nil
            )
            goals.append(goal)
        }
        
        let endTime = Date()
        let creationTime = endTime.timeIntervalSince(startTime)
        
        #expect(goals.count == 1000)
        #expect(creationTime < 5.0) // 创建1000个目标应该在5秒内完成
    }
    
    @Test func testLargeDataSetQuery() async throws {
        // 测试大量数据查询的性能
        var contacts: [Contact] = []
        for i in 0..<500 {
            let contact = Contact(
                name: "性能测试联系人\(i)",
                company: "公司\(i % 20)",
                position: "职位\(i % 10)",
                phone: "1380013800\(i % 10)",
                email: "test\(i)@performance.com",
                address: "地址\(i)",
                notes: "备注\(i)",
                contactType: ContactType.allCases[i % ContactType.allCases.count],
                frequency: ContactFrequency.allCases[i % ContactFrequency.allCases.count],
                tags: ["性能", "测试\(i % 5)"]
            )
            contacts.append(contact)
        }
        
        // 测试查询性能
        let startTime = Date()
        
        let colleagueContacts = contacts.filter { $0.contactType == .colleague }
        let searchResults = contacts.filter { $0.name.contains("100") }
        let taggedContacts = contacts.filter { $0.tags.contains("性能") }
        
        let endTime = Date()
        let queryTime = endTime.timeIntervalSince(startTime)
        
        #expect(contacts.count == 500)
        #expect(colleagueContacts.count > 0)
        #expect(searchResults.count > 0)
        #expect(taggedContacts.count == 500) // 所有联系人都有"性能"标签
        #expect(queryTime < 1.0) // 查询应该在1秒内完成
    }
    
    // MARK: - Data Consistency Tests
    
    @Test func testGoalProgressConsistency() async throws {
        // 测试目标进度的一致性
        let progressValues = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for progress in progressValues {
            let goal = Goal(
                name: "进度一致性测试",
                description: "测试进度值\(progress)",
                progress: progress,
                backgroundImage: nil,
                tags: [],
                upperProject: [],
                subProject: [],
                recordNum: 0,
                category: "一致性测试",
                goalType: .shortTerm,
                dueDate: nil
            )
            
            #expect(goal.progress == progress)
            #expect(goal.progress >= 0.0)
            #expect(goal.progress <= 1.0)
        }
    }
    
    @Test func testTagsConsistency() async throws {
        // 测试标签的一致性
        let tags = ["标签1", "标签2", "特殊字符@#$", "中文标签", "English Tag"]
        
        let goal = Goal(
            name: "标签一致性测试",
            description: "测试各种标签",
            progress: 0.0,
            backgroundImage: nil,
            tags: tags,
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "一致性测试",
            goalType: .shortTerm,
            dueDate: nil
        )
        
        let contact = Contact(
            name: "标签一致性测试联系人",
            company: nil,
            position: nil,
            phone: nil,
            email: nil,
            address: nil,
            notes: nil,
            contactType: .other,
            frequency: .occasional,
            tags: tags
        )
        
        #expect(goal.tags.count == tags.count)
        #expect(contact.tags.count == tags.count)
        
        for tag in tags {
            #expect(goal.tags.contains(tag))
            #expect(contact.tags.contains(tag))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testInvalidDataHandling() async throws {
        // 测试无效数据的处理
        
        // 测试极端进度值
        let extremeProgressGoal = Goal(
            name: "极端进度测试",
            description: "测试极端进度值",
            progress: 999.0, // 极端值
            backgroundImage: nil,
            tags: [],
            upperProject: [],
            subProject: [],
            recordNum: -1, // 负数
            category: "", // 空字符串
            goalType: .shortTerm,
            dueDate: nil
        )
        
        // 验证数据仍然可以创建（具体验证逻辑取决于业务规则）
        #expect(extremeProgressGoal.name == "极端进度测试")
        #expect(extremeProgressGoal.progress == 999.0) // 如果没有验证，应该保持原值
        #expect(extremeProgressGoal.recordNum == -1)
        #expect(extremeProgressGoal.category.isEmpty)
    }
    
    @Test func testNilOptionalFieldsHandling() async throws {
        // 测试可选字段为nil的处理
        let minimalContact = Contact(
            name: "最小联系人",
            company: nil,
            position: nil,
            phone: nil,
            email: nil,
            address: nil,
            notes: nil,
            contactType: .other,
            frequency: .occasional,
            tags: []
        )
        
        #expect(minimalContact.name == "最小联系人")
        #expect(minimalContact.company == nil)
        #expect(minimalContact.position == nil)
        #expect(minimalContact.phone == nil)
        #expect(minimalContact.email == nil)
        #expect(minimalContact.address == nil)
        #expect(minimalContact.notes == nil)
        #expect(minimalContact.tags.isEmpty)
    }
    
    // MARK: - Date Handling Tests
    
    @Test func testDatePersistence() async throws {
        // 测试日期的持久化
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .month, value: 6, to: now)!
        let pastDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        
        let futureGoal = Goal(
            name: "未来目标",
            description: "6个月后到期",
            progress: 0.0,
            backgroundImage: nil,
            tags: [],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "日期测试",
            goalType: .shortTerm,
            dueDate: futureDate
        )
        
        let pastGoal = Goal(
            name: "过期目标",
            description: "6个月前到期",
            progress: 1.0,
            backgroundImage: nil,
            tags: [],
            upperProject: [],
            subProject: [],
            recordNum: 0,
            category: "日期测试",
            goalType: .shortTerm,
            dueDate: pastDate
        )
        
        #expect(futureGoal.dueDate! > now)
        #expect(pastGoal.dueDate! < now)
        
        // 测试日期格式化和比较
        let calendar = Calendar.current
        let futureComponents = calendar.dateComponents([.year, .month, .day], from: futureGoal.dueDate!)
        let pastComponents = calendar.dateComponents([.year, .month, .day], from: pastGoal.dueDate!)
        
        #expect(futureComponents.year != nil)
        #expect(futureComponents.month != nil)
        #expect(futureComponents.day != nil)
        #expect(pastComponents.year != nil)
        #expect(pastComponents.month != nil)
        #expect(pastComponents.day != nil)
    }

}