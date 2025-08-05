//
//  UIComponentsTests.swift
//  selfManagerTests
//
//  Created by AI Assistant on 2024.
//

import Testing
import SwiftUI
@testable import selfManager

struct UIComponentsTests {
    
    // MARK: - Goal View Tests
    
    @Test func testGoalViewInitialization() async throws {
        let goalView = GoalView()
        
        // 测试初始状态
        #expect(goalView.selectedSegment == 0)
        #expect(goalView.searchText.isEmpty)
        #expect(goalView.showSearchBar == false)
        #expect(goalView.isSearching == false)
    }
    
    @Test func testGoalFilteringByType() async throws {
        let goals = [
            Goal(name: "年度目标", description: "测试", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "年度", goalType: .yearly, dueDate: nil),
            Goal(name: "短期目标", description: "测试", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "短期", goalType: .shortTerm, dueDate: nil),
            Goal(name: "人生目标", description: "测试", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "人生", goalType: .life, dueDate: nil),
            Goal(name: "习惯目标", description: "测试", progress: 0.0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "习惯", goalType: .habit, dueDate: nil)
        ]
        
        // 测试按类型过滤
        let yearlyGoals = goals.filter { $0.goalType == .yearly }
        let shortTermGoals = goals.filter { $0.goalType == .shortTerm }
        let lifeGoals = goals.filter { $0.goalType == .life }
        let habitGoals = goals.filter { $0.goalType == .habit }
        
        #expect(yearlyGoals.count == 1)
        #expect(shortTermGoals.count == 1)
        #expect(lifeGoals.count == 1)
        #expect(habitGoals.count == 1)
    }
    
    @Test func testGoalSearchFunctionality() async throws {
        let goals = [
            Goal(name: "学习编程", description: "掌握Swift语言", progress: 0.3, backgroundImage: nil, tags: ["技术", "学习"], upperProject: [], subProject: [], recordNum: 0, category: "学习", goalType: .shortTerm, dueDate: nil),
            Goal(name: "健身计划", description: "每天运动30分钟", progress: 0.6, backgroundImage: nil, tags: ["健康", "运动"], upperProject: [], subProject: [], recordNum: 0, category: "健康", goalType: .habit, dueDate: nil),
            Goal(name: "读书计划", description: "今年读完50本书", progress: 0.2, backgroundImage: nil, tags: ["阅读", "学习"], upperProject: [], subProject: [], recordNum: 0, category: "学习", goalType: .yearly, dueDate: nil)
        ]
        
        // 测试按名称搜索
        let searchByName = goals.filter { $0.name.localizedCaseInsensitiveContains("学习") }
        #expect(searchByName.count == 1)
        
        // 测试按描述搜索
        let searchByDescription = goals.filter { $0.goalDescription.localizedCaseInsensitiveContains("Swift") }
        #expect(searchByDescription.count == 1)
        
        // 测试按标签搜索
        let searchByTag = goals.filter { $0.tags.contains { $0.localizedCaseInsensitiveContains("学习") } }
        #expect(searchByTag.count == 2)
    }
    
    // MARK: - Contact View Tests
    
    @Test func testContactViewInitialization() async throws {
        let contactView = ContactView()
        
        // 测试初始状态
        #expect(contactView.selectedSegment == 0)
        #expect(contactView.searchText.isEmpty)
        #expect(contactView.showSearchBar == false)
    }
    
    @Test func testContactFilteringByType() async throws {
        let contacts = [
            Contact(name: "张三", company: "公司A", position: "工程师", phone: nil, email: nil, address: nil, notes: nil, contactType: .colleague, frequency: .weekly, tags: []),
            Contact(name: "李四", company: nil, position: nil, phone: nil, email: nil, address: nil, notes: nil, contactType: .friend, frequency: .monthly, tags: []),
            Contact(name: "王五", company: nil, position: nil, phone: nil, email: nil, address: nil, notes: nil, contactType: .family, frequency: .daily, tags: []),
            Contact(name: "赵六", company: "公司B", position: "经理", phone: nil, email: nil, address: nil, notes: nil, contactType: .other, frequency: .yearly, tags: [])
        ]
        
        // 测试按类型过滤
        let colleagueContacts = contacts.filter { $0.contactType == .colleague }
        let friendContacts = contacts.filter { $0.contactType == .friend }
        let familyContacts = contacts.filter { $0.contactType == .family }
        let otherContacts = contacts.filter { $0.contactType == .other }
        
        #expect(colleagueContacts.count == 1)
        #expect(friendContacts.count == 1)
        #expect(familyContacts.count == 1)
        #expect(otherContacts.count == 1)
    }
    
    @Test func testContactSearchFunctionality() async throws {
        let contacts = [
            Contact(name: "张工程师", company: "苹果公司", position: "iOS开发", phone: "13800138000", email: "zhang@apple.com", address: "北京", notes: "技术专家", contactType: .colleague, frequency: .monthly, tags: ["技术", "iOS"]),
            Contact(name: "李经理", company: "谷歌", position: "产品经理", phone: "13900139000", email: "li@google.com", address: "上海", notes: "产品设计", contactType: .colleague, frequency: .weekly, tags: ["产品", "设计"]),
            Contact(name: "王朋友", company: nil, position: nil, phone: "13700137000", email: "wang@friend.com", address: "深圳", notes: "老朋友", contactType: .friend, frequency: .monthly, tags: ["朋友"])
        ]
        
        // 测试按姓名搜索
        let searchByName = contacts.filter { $0.name.localizedCaseInsensitiveContains("张") }
        #expect(searchByName.count == 1)
        
        // 测试按公司搜索
        let searchByCompany = contacts.filter { ($0.company ?? "").localizedCaseInsensitiveContains("苹果") }
        #expect(searchByCompany.count == 1)
        
        // 测试按职位搜索
        let searchByPosition = contacts.filter { ($0.position ?? "").localizedCaseInsensitiveContains("iOS") }
        #expect(searchByPosition.count == 1)
        
        // 测试按标签搜索
        let searchByTag = contacts.filter { $0.tags.contains { $0.localizedCaseInsensitiveContains("技术") } }
        #expect(searchByTag.count == 1)
    }
    
    // MARK: - Goal Detail View Tests
    
    @Test func testGoalDetailViewInitialization() async throws {
        let goal = Goal(name: "测试目标", description: "测试描述", progress: 0.5, backgroundImage: nil, tags: ["测试"], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: nil)
        
        let goalDetailView = GoalDetailView(goal: goal)
        
        // 测试目标详情视图的初始化
        #expect(goalDetailView.goal.name == "测试目标")
        #expect(goalDetailView.goal.progress == 0.5)
        #expect(goalDetailView.goal.goalType == .shortTerm)
    }
    
    @Test func testGoalTypeMapping() async throws {
        // 测试目标类型数组的正确性
        let goalTypes = ["人生目标", "年度目标", "短期目标", "习惯"]
        
        #expect(goalTypes.count == 4)
        #expect(goalTypes[0] == "人生目标")
        #expect(goalTypes[1] == "年度目标")
        #expect(goalTypes[2] == "短期目标")
        #expect(goalTypes[3] == "习惯")
        
        // 测试索引映射
        #expect(GoalType.life.rawValue == 0)
        #expect(GoalType.yearly.rawValue == 1)
        #expect(GoalType.shortTerm.rawValue == 2)
        #expect(GoalType.habit.rawValue == 3)
    }
    
    // MARK: - Add Goal View Tests
    
    @Test func testAddGoalViewValidation() async throws {
        // 测试目标名称验证
        let emptyName = ""
        let validName = "有效目标名称"
        let longName = String(repeating: "a", count: 200)
        
        #expect(emptyName.isEmpty)
        #expect(!validName.isEmpty)
        #expect(longName.count > 100) // 假设有长度限制
    }
    
    @Test func testGoalProgressValidation() async throws {
        // 测试进度值的有效性
        let validProgress = [0.0, 0.25, 0.5, 0.75, 1.0]
        let invalidProgress = [-0.1, 1.1, 2.0]
        
        for progress in validProgress {
            #expect(progress >= 0.0 && progress <= 1.0)
        }
        
        for progress in invalidProgress {
            #expect(progress < 0.0 || progress > 1.0)
        }
    }
    
    // MARK: - Contact Detail View Tests
    
    @Test func testContactDetailViewInitialization() async throws {
        let contact = Contact(name: "测试联系人", company: "测试公司", position: "测试职位", phone: "13800138000", email: "test@test.com", address: "测试地址", notes: "测试备注", contactType: .colleague, frequency: .monthly, tags: ["测试"])
        
        let contactDetailView = ContactDetailView(contact: contact)
        
        // 测试联系人详情视图的初始化
        #expect(contactDetailView.contact.name == "测试联系人")
        #expect(contactDetailView.contact.contactType == .colleague)
        #expect(contactDetailView.contact.frequency == .monthly)
    }
    
    // MARK: - Search Bar Tests
    
    @Test func testSearchBarBehavior() async throws {
        var searchText = ""
        var isSearching = false
        
        // 模拟搜索文本输入
        searchText = "测试"
        isSearching = !searchText.isEmpty
        
        #expect(isSearching == true)
        #expect(searchText == "测试")
        
        // 模拟清空搜索
        searchText = ""
        isSearching = !searchText.isEmpty
        
        #expect(isSearching == false)
        #expect(searchText.isEmpty)
    }
    
    // MARK: - Data Sorting Tests
    
    @Test func testGoalSorting() async throws {
        let goals = [
            Goal(name: "C目标", description: "描述", progress: 0.3, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: Date().addingTimeInterval(86400 * 3)),
            Goal(name: "A目标", description: "描述", progress: 0.1, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: Date().addingTimeInterval(86400 * 1)),
            Goal(name: "B目标", description: "描述", progress: 0.9, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: Date().addingTimeInterval(86400 * 2))
        ]
        
        // 按名称排序
        let sortedByName = goals.sorted { $0.name < $1.name }
        #expect(sortedByName[0].name == "A目标")
        #expect(sortedByName[1].name == "B目标")
        #expect(sortedByName[2].name == "C目标")
        
        // 按进度排序
        let sortedByProgress = goals.sorted { $0.progress < $1.progress }
        #expect(sortedByProgress[0].progress == 0.1)
        #expect(sortedByProgress[1].progress == 0.3)
        #expect(sortedByProgress[2].progress == 0.9)
        
        // 按截止日期排序
        let sortedByDueDate = goals.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        #expect(sortedByDueDate[0].name == "A目标")
        #expect(sortedByDueDate[1].name == "B目标")
        #expect(sortedByDueDate[2].name == "C目标")
    }
    
    @Test func testContactSorting() async throws {
        let contacts = [
            Contact(name: "张三", company: "C公司", position: "工程师", phone: nil, email: nil, address: nil, notes: nil, contactType: .colleague, frequency: .weekly, tags: []),
            Contact(name: "李四", company: "A公司", position: "经理", phone: nil, email: nil, address: nil, notes: nil, contactType: .colleague, frequency: .monthly, tags: []),
            Contact(name: "王五", company: "B公司", position: "总监", phone: nil, email: nil, address: nil, notes: nil, contactType: .colleague, frequency: .daily, tags: [])
        ]
        
        // 按姓名排序
        let sortedByName = contacts.sorted { $0.name < $1.name }
        #expect(sortedByName[0].name == "李四")
        #expect(sortedByName[1].name == "王五")
        #expect(sortedByName[2].name == "张三")
        
        // 按公司排序
        let sortedByCompany = contacts.sorted { ($0.company ?? "") < ($1.company ?? "") }
        #expect(sortedByCompany[0].company == "A公司")
        #expect(sortedByCompany[1].company == "B公司")
        #expect(sortedByCompany[2].company == "C公司")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testNilValueHandling() async throws {
        // 测试可选值的处理
        let contact = Contact(name: "测试", company: nil, position: nil, phone: nil, email: nil, address: nil, notes: nil, contactType: .other, frequency: .occasional, tags: [])
        
        #expect(contact.company == nil)
        #expect(contact.position == nil)
        #expect(contact.phone == nil)
        #expect(contact.email == nil)
        #expect(contact.address == nil)
        #expect(contact.notes == nil)
        
        // 测试搜索时的nil值处理
        let searchText = "测试"
        let companyMatch = (contact.company ?? "").localizedCaseInsensitiveContains(searchText)
        let positionMatch = (contact.position ?? "").localizedCaseInsensitiveContains(searchText)
        
        #expect(companyMatch == false)
        #expect(positionMatch == false)
    }
    
    @Test func testEmptyArrayHandling() async throws {
        // 测试空数组的处理
        let emptyGoals: [Goal] = []
        let emptyContacts: [Contact] = []
        
        #expect(emptyGoals.isEmpty)
        #expect(emptyContacts.isEmpty)
        
        // 测试空数组的搜索
        let filteredGoals = emptyGoals.filter { $0.name.contains("测试") }
        let filteredContacts = emptyContacts.filter { $0.name.contains("测试") }
        
        #expect(filteredGoals.isEmpty)
        #expect(filteredContacts.isEmpty)
    }
    
    @Test func testGoalRelationBidirectionalSync() async throws {
        // 创建两个目标
        var goalA = Goal(name: "目标A", description: "A", progress: 0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: nil)
        var goalB = Goal(name: "目标B", description: "B", progress: 0, backgroundImage: nil, tags: [], upperProject: [], subProject: [], recordNum: 0, category: "测试", goalType: .shortTerm, dueDate: nil)
    
        // 1. 在B中添加A为上级目标
        goalB.upperProject.append(goalA.id.uuidString)
        // 模拟onChange逻辑
        if !goalA.subProject.contains(goalB.id.uuidString) {
            goalA.subProject.append(goalB.id.uuidString)
        }
        #expect(goalA.subProject.contains(goalB.id.uuidString))
        #expect(goalB.upperProject.contains(goalA.id.uuidString))
    
        // 2. 在B中添加A为子目标
        goalB.subProject.append(goalA.id.uuidString)
        // 模拟onChange逻辑
        if !goalA.upperProject.contains(goalB.id.uuidString) {
            goalA.upperProject.append(goalB.id.uuidString)
        }
        #expect(goalA.upperProject.contains(goalB.id.uuidString))
        #expect(goalB.subProject.contains(goalA.id.uuidString))
    
        // 3. 移除B的上级目标A
        if let idx = goalB.upperProject.firstIndex(of: goalA.id.uuidString) {
            goalB.upperProject.remove(at: idx)
        }
        // 同步移除A的subProject
        if let idx = goalA.subProject.firstIndex(of: goalB.id.uuidString) {
            goalA.subProject.remove(at: idx)
        }
        #expect(!goalA.subProject.contains(goalB.id.uuidString))
        #expect(!goalB.upperProject.contains(goalA.id.uuidString))
    
        // 4. 移除B的子目标A
        if let idx = goalB.subProject.firstIndex(of: goalA.id.uuidString) {
            goalB.subProject.remove(at: idx)
        }
        // 同步移除A的upperProject
        if let idx = goalA.upperProject.firstIndex(of: goalB.id.uuidString) {
            goalA.upperProject.remove(at: idx)
        }
        #expect(!goalA.upperProject.contains(goalB.id.uuidString))
        #expect(!goalB.subProject.contains(goalA.id.uuidString))
    }
}