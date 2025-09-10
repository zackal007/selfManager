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
    
    // 观察TagColorManager的变化以实现即时更新
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
    @State private var searchText = ""
    @State private var showingAddTag = false
    @State private var newTag = ""
    @State private var selectedTagType: TagType = .goal // 默认添加到目标类型
    
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
        
        // 从Tag对象中获取所有标签名称（包括未关联的标签）
        tags.forEach { tagNames.insert($0.name) }
        
        // 从关联的元素中获取标签名称（确保完整性）
        goals.forEach { tagNames.formUnion($0.tags) }
        contacts.forEach { tagNames.formUnion($0.tags) }
        if let user = users.first {
            tagNames.formUnion(user.tags)
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
                
                // 页签栏已移除
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
            
            // 标签网格布局 - iOS原生风格的按钮块
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(allTags, id: \.self) { tag in
                        NavigationLink(destination: TagDetailView(tag: tag, tagType: selectedTagType)) {
                            VStack(spacing: 12) {
                                // 标签主体内容
                                VStack(spacing: 8) {
                                    // 标签名称
                                    Text(tag)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .minimumScaleFactor(0.8)
                                    
                                    // 分类标签（如果有）
                                    if let categoryName = getCategoryName(for: tag) {
                                        Text(categoryName)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.2))
                                            )
                                    }
                                }
                                
                                Spacer()
                                
                                // 底部信息区域
                                HStack {
                                    // 标签描述（如果有且不为空）
                                    if let tagObj = getTagObject(for: tag), !tagObj.tagDescription.isEmpty {
                                        Text(tagObj.tagDescription)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    
                                    Spacer()
                                    
                                    // 计数徽章
                                    Text("\(getTagItemCount(tag: tag))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(tagColor(for: tag))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                                }
                            }
                            .padding(16)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                tagColor(for: tag),
                                                tagColor(for: tag).opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: tagColor(for: tag).opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: tagColor(for: tag))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
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
                        
                        // 类型选择器已移除，默认添加到目标
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
                color: "#007AFF", // 默认使用iOS系统蓝色
                categoryID: nil
            )
            modelContext.insert(newTagObject)
            
            // 新创建的标签不自动关联到任何元素
            // 用户可以在需要时手动添加标签到具体的目标、联系人或用户
            
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
    
    // 观察TagColorManager的变化以实现即时更新
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
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
        HStack(spacing: 12) {
            // 左侧彩色指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)
                .frame(width: 3, height: 40)
                .opacity(0.8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(goal.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if !goal.goalDescription.isEmpty {
                    Text(goal.goalDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // 目标列表部分
    private var goalListSection: some View {
        Group {
            if tagType == .all || tagType == .goal, !taggedGoals.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("目标")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(taggedGoals.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.systemGray5))
                            )
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(taggedGoals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                goalItemView(for: goal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.all, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // 创建单个联系人项视图
    private func contactItemView(for contact: Contact) -> some View {
        HStack(spacing: 12) {
            // 左侧彩色指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.green)
                .frame(width: 3, height: 40)
                .opacity(0.8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let company = contact.company, !company.isEmpty {
                    Text(company)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // 联系人列表部分
    private var contactListSection: some View {
        Group {
            if tagType == .all || tagType == .contact, !taggedContacts.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("人脉")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(taggedContacts.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.systemGray5))
                            )
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(taggedContacts) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                contactItemView(for: contact)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.all, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // 创建用户信息项视图
    private func userItemView(for user: User) -> some View {
        HStack(spacing: 12) {
            // 左侧彩色指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.purple)
                .frame(width: 3, height: 40)
                .opacity(0.8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if !user.userDescription.isEmpty {
                    Text(user.userDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // 用户信息部分
    private var userInfoSection: some View {
        Group {
            if (tagType == .all || tagType == .user) && userHasTag, let user = users.first {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("个人")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("1")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.systemGray5))
                            )
                    }
                    
                    NavigationLink(destination: UserEditView(user: user)) {
                        userItemView(for: user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.all, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标签信息头部
                tagInfoSection
                    .padding(.horizontal, 20)
                
                // 内容区域
                VStack(spacing: 20) {
                    goalListSection
                    contactListSection
                    userInfoSection
                }
                .padding(.horizontal, 20)
                
                // 底部间距
                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemGroupedBackground),
                    Color(UIColor.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("标签: \(tag)")
        .navigationBarTitleDisplayMode(.large)
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
        VStack(alignment: .leading, spacing: 16) {
            // 标签名称和分类区域
            HStack(spacing: 12) {
                // 左侧彩色指示条
                RoundedRectangle(cornerRadius: 2)
                    .fill(tagColor)
                    .frame(width: 3, height: 48)
                    .opacity(0.8)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(tag)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let category = tagCategory {
                            Text(category.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(tagColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tagColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(tagColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    if let description = tagDescription, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
            }
            
            // 操作按钮区域
            HStack(spacing: 12) {
                Spacer()
                
                // 编辑按钮
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("编辑")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
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
                            .shadow(color: Color(UIColor.systemBlue).opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                
                // 删除按钮
                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                        Text("删除")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red,
                                        Color.red.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
            }
        }
        .padding(.all, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 1)
                )
        )
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
        let goalStat: some View = createStatItem(count: taggedGoals.count, title: "目标", icon: "target", color: .blue)
        let contactStat: some View = createStatItem(count: taggedContacts.count, title: "联系人", icon: "person.2", color: .green)
        let userStat: some View = createStatItem(count: userHasTag ? 1 : 0, title: "个人", icon: "person", color: .purple)
        
        return HStack(spacing: 16) {
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground),
                            Color(UIColor.systemGray6).opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.separator).opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // 创建统计项 - 优化类型推断
    private func createStatItem(count: Int, title: String, icon: String, color: Color) -> some View {
        // 使用明确的类型注解和中间变量来帮助编译器进行类型推断
        let iconView: some View = Image(systemName: icon)
            .foregroundColor(color)
            .font(.system(size: 18, weight: .semibold))
        
        let countText: some View = Text("\(count)")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.primary)
        
        let titleText: some View = Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
        
        return VStack(spacing: 8) {
            HStack(spacing: 6) {
                iconView
                countText
            }
            titleText
        }
        .frame(minWidth: 70)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground),
                            color.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(count > 0 ? 1.0 : 0.95)
        .opacity(count > 0 ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: count)
    }
}

#Preview {
    TagsView()
}