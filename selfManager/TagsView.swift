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
    @Query private var tagCategories: [TagCategory]
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
    
    // 查询所有Tag对象
    @Query private var tags: [Tag]
    
    // 获取所有标签
    private var allTags: [String] {
        var tagNames = Set<String>()
        
        // 根据选择的标签类型筛选
        switch selectedTagType {
        case .all:
            // 合并所有标签
            goals.forEach { tagNames.formUnion($0.tags) }
            contacts.forEach { tagNames.formUnion($0.tags) }
            if let user = users.first {
                tagNames.formUnion(user.tags)
            }
        case .goal:
            goals.forEach { tagNames.formUnion($0.tags) }
        case .contact:
            contacts.forEach { tagNames.formUnion($0.tags) }
        case .user:
            if let user = users.first {
                tagNames.formUnion(user.tags)
            }
        }
        
        // 搜索过滤
        if !searchText.isEmpty {
            return Array(tagNames).filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
        }
        
        return Array(tagNames).sorted()
    }
    
    // 获取标签对象
    private func getTagObject(for tagName: String) -> Tag? {
        return tags.first { $0.name == tagName }
    }
    
    // 获取标签分类名称
    private func getCategoryName(for tagName: String) -> String? {
        guard let tag = getTagObject(for: tagName),
              let categoryID = tag.categoryID else { return nil }
        
        return tagCategories.first { $0.id == categoryID }?.name
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
    
    // 为标签生成颜色 - 使用TagColorManager
    private func tagColor(for tag: String) -> Color {
        return TagColorManager.shared.getColor(for: tag)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏 - 优化设计
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("搜索标签", text: $searchText)
                            .font(.system(size: 16))
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    searchText = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
                }
                
                // 标签类型选择器 - 改进样式
                Picker("标签类型", selection: $selectedTagType) {
                    ForEach(TagType.allCases) { type in
                        Text(type.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // 标签列表 - 优化设计
            List {
                ForEach(allTags, id: \.self) { tag in
                    NavigationLink(destination: TagDetailView(tag: tag, tagType: selectedTagType)) {
                        HStack(spacing: 16) {
                            // 标签颜色指示器 - 更细更优雅
                            RoundedRectangle(cornerRadius: 2)
                                .fill(tagColor(for: tag))
                                .frame(width: 3, height: 36)
                                .opacity(0.8)
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tagColor(for: tag))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 12) {
                                    // 标签名称
                                    Text(tag)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .transition(.opacity.combined(with: .scale))
                                    
                                    // 分类标签
                                    if let categoryName = getCategoryName(for: tag) {
                                        Text(categoryName)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(tagColor(for: tag))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(tagColor(for: tag).opacity(0.1))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(tagColor(for: tag).opacity(0.3), lineWidth: 0.5)
                                                    )
                                            )
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                    
                                    Spacer()
                                    
                                    // 计数徽章 - 使用标签颜色
                                    Text("\(getTagItemCount(tag: tag))")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [tagColor(for: tag), tagColor(for: tag).opacity(0.7)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .shadow(color: tagColor(for: tag).opacity(0.3), radius: 2, x: 0, y: 1)
                                        .scaleEffect(1.0)
                                        .animation(.bouncy(duration: 0.4), value: getTagItemCount(tag: tag))
                                }
                                
                                // 标签描述
                                if let tagObj = getTagObject(for: tag), !tagObj.tagDescription.isEmpty {
                                    Text(tagObj.tagDescription)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 0.5)
                        )
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.2), value: allTags)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .listStyle(PlainListStyle())
            .background(Color(UIColor.systemGroupedBackground))
            .scrollContentBackground(.hidden)
        }


        .navigationTitle("标签管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // 添加标签按钮
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showingAddTag = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .scaleEffect(showingAddTag ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: showingAddTag)
                    }
                    
                    // 管理分类按钮
                    NavigationLink(destination: TagCategoryListView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("分类")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemBlue).opacity(0.1))
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTag) {
            addTagView
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
    
    // 添加标签视图 - 优化设计
    private var addTagView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 头部区域
                VStack(spacing: 24) {
                    // 图标和标题
                    VStack(spacing: 12) {
                        Image(systemName: "tag.circle.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Color(UIColor.systemBlue))
                        
                        Text("添加新标签")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 32)
                    
                    // 输入框区域
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("标签名称")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("请输入标签名称", text: $newTag)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(newTag.isEmpty ? Color.clear : Color(UIColor.systemBlue), lineWidth: 2)
                                        )
                                )
                        }
                        
                        // 类型选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("添加到")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Picker("添加到", selection: $selectedTagType) {
                                ForEach(TagType.allCases.filter { $0 != .all }, id: \.self) { type in
                                    Text(type.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 底部按钮区域
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            addTag()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("添加标签")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(UIColor.systemBlue),
                                            Color(UIColor.systemBlue).opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(UIColor.systemBlue).opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    
                    Button(action: {
                        showingAddTag = false
                        newTag = ""
                    }) {
                        Text("取消")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemGray6))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // 添加标签方法
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedTag.isEmpty {
            // 创建新的Tag对象
            let newTagObject = Tag(
                name: trimmedTag,
                tagDescription: "",
                color: TagColorManager.shared.getColor(for: trimmedTag).toHex() ?? "#0000FF",
                categoryID: nil
            )
            modelContext.insert(newTagObject)
            
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
    @Query private var tagCategories: [TagCategory]
    @Query private var tagObjects: [Tag]
    @Environment(\.dismiss) private var dismiss
    
    let tag: String
    let tagType: TagsView.TagType
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    // 获取标签对象
    private var tagObject: Tag? {
        return tagObjects.first { $0.name == tag }
    }
    
    // 获取标签分类
    private var tagCategory: TagCategory? {
        guard let categoryID = tagObject?.categoryID else { return nil }
        return tagCategories.first { $0.id == categoryID }
    }
    
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
    
    // 为标签生成颜色 - 使用TagColorManager
    private func tagColor(for tag: String) -> Color {
        return TagColorManager.shared.getColor(for: tag)
    }
    
    // 将body拆分为更小的组件，避免复杂表达式
    private var tagInfoSection: some View {
        Section {
            let tagHeader = TagInfoHeader(
                tag: tag, 
                tagColor: tagColor(for: tag), 
                onDelete: { showingDeleteAlert = true },
                onEdit: { showingEditSheet = true },
                tagCategory: tagCategory,
                tagDescription: tagObject?.tagDescription
            )
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
        .sheet(isPresented: $showingEditSheet) {
                TagEditView(tag: tag, tagType: tagType)
                    .environment(\.colorScheme, .light) // 确保预览在编辑器中使用一致的配色方案
                    .onDisappear {
                        // 标签编辑弹窗关闭后，强制刷新标签相关数据
                        // 通过重置@State变量触发视图刷新
                        if let tagObj = tagObject {
                            // 强制刷新标签颜色
                            TagColorManager.shared.refreshColor(for: tag)
                            
                            // 触发UI刷新
                            showingEditSheet = false
                        }
                    }
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
        
        // 删除Tag对象
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == tag })
        if let tagObj = try? modelContext.fetch(descriptor).first {
            modelContext.delete(tagObj)
        }
        
        // 删除标签颜色
        TagColorManager.shared.removeColor(for: tag)
        
        // 保存更改
        do {
            try modelContext.save()
            dismiss()
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
    let onEdit: () -> Void
    var tagCategory: TagCategory?
    var tagDescription: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tag)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(tagColor)
                        
                        if let category = tagCategory {
                            Text(category.name)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let description = tagDescription, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // 编辑按钮
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("编辑")
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.trailing, 8)
                
                // 删除按钮
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除")
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 6)
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