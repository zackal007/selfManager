//
//  TagsView.swift
//  selfManager
//
//  Created by Trae AI on 2024/12/31.
//

import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var contacts: [Contact]
    @Query private var users: [User]
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingAddTag = false
    @State private var newTag = ""
    @State private var selectedTagType: TagType = .all
    
    // 标签类型枚举
    enum TagType: String, CaseIterable, Identifiable {
        case all = "全部"
        case goal = "目标"
        case contact = "人脉"
        case user = "个人"
        
        var id: String { self.rawValue }
    }
    
    // 获取所有标签
    private var allTags: [String] {
        var tags = Set<String>()
        
        // 根据选择的标签类型筛选
        switch selectedTagType {
        case .all:
            // 合并所有标签
            goals.forEach { tags.formUnion($0.tags) }
            contacts.forEach { tags.formUnion($0.tags) }
            if let user = users.first {
                tags.formUnion(user.tags)
            }
        case .goal:
            goals.forEach { tags.formUnion($0.tags) }
        case .contact:
            contacts.forEach { tags.formUnion($0.tags) }
        case .user:
            if let user = users.first {
                tags.formUnion(user.tags)
            }
        }
        
        // 搜索过滤
        if !searchText.isEmpty {
            return Array(tags).filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
        }
        
        return Array(tags).sorted()
    }
    
    // 获取每个标签关联的项目数量
    private func getTagItemCount(tag: String) -> Int {
        var count = 0
        
        // 在"全部"类型下，累加所有类别中的标签出现次数
        if selectedTagType == .all {
            // 累加目标中的标签出现次数
            count += goals.filter { $0.tags.contains(tag) }.count
            
            // 累加联系人中的标签出现次数
            count += contacts.filter { $0.tags.contains(tag) }.count
            
            // 累加用户中的标签出现次数
            if let user = users.first, user.tags.contains(tag) {
                count += 1
            }
        } else {
            // 在特定类别下，只计算该类别中的标签出现次数
            switch selectedTagType {
            case .goal:
                count += goals.filter { $0.tags.contains(tag) }.count
            case .contact:
                count += contacts.filter { $0.tags.contains(tag) }.count
            case .user:
                if let user = users.first, user.tags.contains(tag) {
                    count += 1
                }
            default:
                break
            }
        }
        
        return count
    }
    
    // 为标签生成颜色 - 统一使用系统蓝色
    private func tagColor(for tag: String) -> Color {
        return Color(UIColor.systemBlue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索标签", text: $searchText)
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 6)
                }
            }
            .padding()
            
            // 标签类型选择器
            Picker("标签类型", selection: $selectedTagType) {
                ForEach(TagType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 标签列表
            List {
                ForEach(allTags, id: \.self) { tag in
                    NavigationLink(destination: TagDetailView(tag: tag, tagType: selectedTagType)) {
                        HStack {
                            Text(tag)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(tagColor(for: tag))
                            
                            Spacer()
                            
                            Text("\(getTagItemCount(tag: tag))")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.systemBlue))
                                .cornerRadius(10)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }


        .navigationTitle("标签管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTag) {
            addTagView
        }
    }
    
    // 添加标签视图
    private var addTagView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("添加新标签")
                    .font(.headline)
                    .padding(.top, 20)
                
                // 输入框
                TextField("标签名称", text: $newTag)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // 选择器
                VStack(alignment: .leading) {
                    Text("添加到:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                    
                    Picker("添加到", selection: $selectedTagType) {
                        ForEach(TagType.allCases.filter { $0 != .all }, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 按钮
                HStack {
                    Button(action: {
                        showingAddTag = false
                        newTag = ""
                    }) {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        addTag()
                    }) {
                        Text("添加")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemBlue))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    
    // 添加标签方法
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedTag.isEmpty {
            switch selectedTagType {
            case .goal:
                // 添加到所有目标
                for goal in goals {
                    if !goal.tags.contains(trimmedTag) {
                        goal.tags.append(trimmedTag)
                    }
                }
            case .contact:
                // 添加到所有联系人
                for contact in contacts {
                    if !contact.tags.contains(trimmedTag) {
                        contact.tags.append(trimmedTag)
                    }
                }
            case .user:
                // 添加到用户
                if let user = users.first, !user.tags.contains(trimmedTag) {
                    user.tags.append(trimmedTag)
                }
            default:
                break
            }
            
            // 保存更改
            do {
                try modelContext.save()
            } catch {
                print("Failed to save tag: \(error)")
            }
        }
        
        // 重置状态
        newTag = ""
        showingAddTag = false
    }
}

// 标签详情视图
struct TagDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var contacts: [Contact]
    @Query private var users: [User]
    @Environment(\.dismiss) private var dismiss
    
    let tag: String
    let tagType: TagsView.TagType
    
    @State private var showingDeleteAlert = false
    
    // 获取带有此标签的目标
    private var taggedGoals: [Goal] {
        goals.filter { $0.tags.contains(tag) }
    }
    
    // 获取带有此标签的联系人
    private var taggedContacts: [Contact] {
        contacts.filter { $0.tags.contains(tag) }
    }
    
    // 用户是否有此标签
    private var userHasTag: Bool {
        users.first?.tags.contains(tag) ?? false
    }
    
    // 为标签生成颜色 - 统一使用系统蓝色
    private func tagColor(for tag: String) -> Color {
        return Color(UIColor.systemBlue)
    }
    
    // 将body拆分为更小的组件，避免复杂表达式
    private var tagInfoSection: some View {
        Section {
            let tagHeader = TagInfoHeader(tag: tag, tagColor: tagColor(for: tag), onDelete: { showingDeleteAlert = true })
            let statisticsRow = StatisticsRow(tagType: tagType, taggedGoals: taggedGoals, taggedContacts: taggedContacts, userHasTag: userHasTag).padding(.vertical, 6)
            tagHeader
            statisticsRow
        }
    }
    
    // 创建单个目标项视图
    private func goalItemView(for goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.name)
                .font(.system(size: 16))
            
            if !goal.goalDescription.isEmpty {
                Text(goal.goalDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 目标列表部分
    private var goalListSection: some View {
        Group {
            if tagType == .all || tagType == .goal, !taggedGoals.isEmpty {
                Section(header: Text("目标").font(.headline)) {
                    ForEach(taggedGoals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            goalItemView(for: goal)
                        }
                    }
                }
            }
        }
    }
    
    // 创建单个联系人项视图
    private func contactItemView(for contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.name)
                .font(.system(size: 16))
            
            if let company = contact.company, !company.isEmpty {
                Text(company)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 联系人列表部分
    private var contactListSection: some View {
        Group {
            if tagType == .all || tagType == .contact, !taggedContacts.isEmpty {
                Section(header: Text("人脉").font(.headline)) {
                    ForEach(taggedContacts) { contact in
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            contactItemView(for: contact)
                        }
                    }
                }
            }
        }
    }
    
    // 创建用户信息项视图
    private func userItemView(for user: User) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.system(size: 16))
            
            if !user.userDescription.isEmpty {
                Text(user.userDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 用户信息部分
    private var userInfoSection: some View {
        Group {
            if (tagType == .all || tagType == .user) && userHasTag, let user = users.first {
                Section(header: Text("个人").font(.headline)) {
                    NavigationLink(destination: UserEditView(user: user)) {
                        userItemView(for: user)
                    }
                }
            }
        }
    }
    
    var body: some View {
        List {
            tagInfoSection
            goalListSection
            contactListSection
            userInfoSection
        }
        .navigationTitle("标签: \(tag)")
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("删除标签"),
                message: Text("确定要删除标签 \"\(tag)\" 吗？这将从所有相关项目中移除此标签。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteTag()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // 删除标签方法
    private func deleteTag() {
        // 从目标中删除标签
        for goal in taggedGoals {
            if let index = goal.tags.firstIndex(of: tag) {
                goal.tags.remove(at: index)
            }
        }
        
        // 从联系人中删除标签
        for contact in taggedContacts {
            if let index = contact.tags.firstIndex(of: tag) {
                contact.tags.remove(at: index)
            }
        }
        
        // 从用户中删除标签
        if let user = users.first, let index = user.tags.firstIndex(of: tag) {
            user.tags.remove(at: index)
        }
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete tag: \(error)")
        }
    }
}



// 标签信息头部组件
struct TagInfoHeader: View {
    let tag: String
    let tagColor: Color
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(tag)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(tagColor)
                .padding(.vertical, 6)
            Spacer()
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("删除标签")
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// 标签统计行组件
struct StatisticsRow: View {
    let tagType: TagsView.TagType
    let taggedGoals: [Goal]
    let taggedContacts: [Contact]
    let userHasTag: Bool
    
    var body: some View {
        // 使用中间变量来简化条件渲染逻辑
        let goalStat: some View = createStatItem(count: taggedGoals.count, title: "目标", icon: "target")
        let contactStat: some View = createStatItem(count: taggedContacts.count, title: "联系人", icon: "person.2")
        let userStat: some View = createStatItem(count: userHasTag ? 1 : 0, title: "个人", icon: "person")
        
        return HStack(spacing: 15) {
            // 目标统计
            if tagType == .all || tagType == .goal {
                goalStat
            }
            
            // 联系人统计
            if tagType == .all || tagType == .contact {
                contactStat
            }
            
            // 个人统计
            if tagType == .all || tagType == .user {
                userStat
            }
        }
    }
    
    // 创建统计项 - 优化类型推断
    private func createStatItem(count: Int, title: String, icon: String) -> some View {
        // 使用明确的类型注解和中间变量来帮助编译器进行类型推断
        let iconView: some View = Image(systemName: icon)
            .foregroundColor(Color(UIColor.systemBlue))
        
        let countText: some View = Text("\(count)")
            .font(.system(size: 16, weight: .bold))
        
        let titleText: some View = Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
        
        return VStack {
            HStack(spacing: 4) {
                iconView
                countText
            }
            titleText
        }
        .frame(minWidth: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    TagsView()
}