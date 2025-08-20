//
//  TagEditView.swift
//  selfManager
//
//  Created by Trae AI on 2024/12/31.
//

import SwiftUI
import SwiftData

struct TagEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var goals: [Goal]
    @Query private var contacts: [Contact]
    @Query private var users: [User]
    @Query private var tagCategories: [TagCategory]
    
    let originalTag: String
    let tagType: TagsView.TagType
    
    @State private var editedTag: String
    @State private var tagDescription: String = ""
    @State private var selectedColor: Color
    @State private var selectedCategoryID: UUID?
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    
    // 可选的标签颜色
    private let colorOptions: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .mint, .cyan, .red
    ]
    
    // 初始化方法
    init(tag: String, tagType: TagsView.TagType) {
        self.originalTag = tag
        self.tagType = tagType
        
        // 初始化状态变量
        _editedTag = State(initialValue: tag)
        _selectedColor = State(initialValue: TagColorManager.shared.getColor(for: tag))
        
        // 尝试获取Tag对象
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == tag })
        if let existingTag = try? modelContext.fetch(descriptor).first {
            _tagDescription = State(initialValue: existingTag.tagDescription)
            _selectedCategoryID = State(initialValue: existingTag.categoryID)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 标签名称编辑
                Section(header: Text("标签名称")) {
                    TextField("标签名称", text: $editedTag)
                        .padding(.vertical, 8)
                        .onChange(of: editedTag) { oldValue, newValue in
                            // 实时更新标签颜色，确保预览能立即反映变化
                            if !newValue.isEmpty {
                                TagColorManager.shared.setColor(selectedColor, for: newValue)
                            }
                        }
                }
                
                // 标签描述
                Section(header: Text("标签描述")) {
                    TextField("描述（可选）", text: $tagDescription)
                        .padding(.vertical, 8)
                }
                
                // 标签分类
                Section(header: Text("标签分类")) {
                    Picker("选择分类", selection: $selectedCategoryID) {
                        Text("无分类").tag(nil as UUID?)
                        ForEach(tagCategories) { category in
                            Text(category.name).tag(category.id as UUID?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 8)
                    .onChange(of: selectedCategoryID) { oldValue, newValue in
                        // 分类变更时触发UI更新
                        // 这里不需要额外操作，SwiftUI会自动刷新预览
                    }
                    
                    NavigationLink(destination: TagCategoryListView()) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("管理分类")
                        }
                    }
                }
                
                // 标签颜色选择
                Section(header: Text("标签颜色")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                        // 实时更新标签颜色，确保预览能立即反映变化
                                        if !editedTag.isEmpty {
                                            TagColorManager.shared.setColor(color, for: editedTag)
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 实时预览
                Section(header: Text("实时预览")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签外观：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 标签外观预览
                        HStack {
                            Text(editedTag.isEmpty ? "标签名称" : editedTag)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedColor.opacity(0.1))
                                .cornerRadius(16)
                                .animation(.easeInOut(duration: 0.2), value: editedTag)
                                .animation(.easeInOut(duration: 0.2), value: selectedColor)
                            
                            if let categoryID = selectedCategoryID,
                               let category = tagCategories.first(where: { $0.id == categoryID }) {
                                Text(category.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                                    .animation(.easeInOut(duration: 0.2), value: selectedCategoryID)
                            }
                            
                            Spacer()
                        }
                        
                        // 描述预览
                        if !tagDescription.isEmpty {
                            Text(tagDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                                .animation(.easeInOut(duration: 0.2), value: tagDescription)
                        }
                        
                        // 使用场景预览
                        Text("在列表中的显示：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(editedTag.isEmpty ? "标签名称" : editedTag)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedColor)
                                    
                                    if let categoryID = selectedCategoryID,
                                       let category = tagCategories.first(where: { $0.id == categoryID }) {
                                        Text(category.name)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(UIColor.systemGray6))
                                            .cornerRadius(8)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("3")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(UIColor.systemBlue))
                                        .cornerRadius(8)
                                }
                                
                                if !tagDescription.isEmpty {
                                    Text(tagDescription)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(UIColor.systemGray6).opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTag()
                    }
                    .disabled(editedTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(isPresented: $showingSaveAlert) {
                Alert(
                    title: Text("提示"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    // 保存标签方法
    private func saveTag() {
        let trimmedTag = editedTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTag.isEmpty {
            alertMessage = "标签名称不能为空"
            showingSaveAlert = true
            return
        }
        
        // 保存标签颜色
        TagColorManager.shared.setColor(selectedColor, for: trimmedTag)
        
        // 查找或创建Tag对象
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == originalTag })
        let existingTag = try? modelContext.fetch(descriptor).first
        
        if let tag = existingTag {
            // 更新现有标签
            tag.name = trimmedTag
            tag.tagDescription = tagDescription
            tag.color = selectedColor.toHex() ?? "#0000FF"
            tag.categoryID = selectedCategoryID
            tag.modifyTime = Date()
        } else {
            // 创建新标签
            let newTag = Tag(
                name: trimmedTag,
                tagDescription: tagDescription,
                color: selectedColor.toHex() ?? "#0000FF",
                categoryID: selectedCategoryID
            )
            modelContext.insert(newTag)
        }
        
        if trimmedTag != originalTag {
            // 更新标签名称
            TagColorManager.shared.updateTagName(from: originalTag, to: trimmedTag)
            // 更新所有使用此标签的项目
            updateTagInEntities()
        } else {
            // 即使名称没变，也刷新颜色以确保视觉一致性
            TagColorManager.shared.refreshColor(for: trimmedTag)
        }
        
        // 保存更改
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "保存失败: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
    
    // 更新所有使用此标签的实体
    private func updateTagInEntities() {
        let trimmedTag = editedTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 根据标签类型更新相应实体
        switch tagType {
        case .all:
            // 更新所有类型的实体
            updateGoalTags(trimmedTag)
            updateContactTags(trimmedTag)
            updateUserTags(trimmedTag)
        case .goal:
            // 仅更新目标
            updateGoalTags(trimmedTag)
        case .contact:
            // 仅更新联系人
            updateContactTags(trimmedTag)
        case .user:
            // 仅更新用户
            updateUserTags(trimmedTag)
        }
    }
    
    // 更新目标标签
    private func updateGoalTags(_ newTag: String) {
        for goal in goals {
            if let index = goal.tags.firstIndex(of: originalTag) {
                goal.tags[index] = newTag
            }
        }
    }
    
    // 更新联系人标签
    private func updateContactTags(_ newTag: String) {
        for contact in contacts {
            if let index = contact.tags.firstIndex(of: originalTag) {
                contact.tags[index] = newTag
            }
        }
    }
    
    // 更新用户标签
    private func updateUserTags(_ newTag: String) {
        if let user = users.first, let index = user.tags.firstIndex(of: originalTag) {
            user.tags[index] = newTag
        }
    }
}

#Preview {
    TagEditView(tag: "示例标签", tagType: .all)
}