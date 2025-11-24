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
    @Environment(\.presentationMode) var presentationMode
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
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部预览区域
                    VStack(spacing: 20) {
                        // 标签预览
                        VStack(spacing: 12) {
                            Text("preview".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 12, height: 12)
                                
                                Text(editedTag.isEmpty ? "tag_name_label".localized : editedTag)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                if let categoryID = selectedCategoryID,
                                   let category = tagCategories.first(where: { $0.id == categoryID }) {
                                    Text("·")
                                        .foregroundColor(.secondary)
                                    Text(category.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(UIColor.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemGray6).opacity(0.3))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    // 表单区域
                    VStack(spacing: 24) {
                        // 基本信息
                        VStack(spacing: 16) {
                            HStack {
                                Text("basic_info".localized)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
                                // 标签名称
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("tag_name_label".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    TextField("tag_name_placeholder".localized, text: $editedTag)
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(UIColor.systemBackground))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(editedTag.isEmpty ? Color(UIColor.systemGray4) : selectedColor, lineWidth: editedTag.isEmpty ? 1 : 2)
                                                )
                                                .scaleEffect(editedTag.isEmpty ? 1.0 : 1.02)
                                                .animation(.easeInOut(duration: 0.2), value: editedTag.isEmpty)
                                        )
                                        .onChange(of: editedTag) { oldValue, newValue in
                                            // 实时更新标签颜色，确保预览能立即反映变化
                                            if !newValue.isEmpty {
                                                TagColorManager.shared.setColor(selectedColor, for: newValue)
                                            }
                                        }
                                }
                                
                                // 描述
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("tag_description_optional_label".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    TextField("tag_description_placeholder".localized, text: $tagDescription)
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(UIColor.systemBackground))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(tagDescription.isEmpty ? Color(UIColor.systemGray4) : selectedColor.opacity(0.6), lineWidth: tagDescription.isEmpty ? 1 : 2)
                                                )
                                                .scaleEffect(tagDescription.isEmpty ? 1.0 : 1.01)
                                                .animation(.easeInOut(duration: 0.2), value: tagDescription.isEmpty)
                                        )
                                }
                                
                                // 分类选择
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("category".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Menu {
                                        Button("no_category".localized) {
                                            selectedCategoryID = nil
                                        }
                                        
                                        ForEach(tagCategories) { category in
                                            Button(category.name) {
                                                selectedCategoryID = category.id
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            if let categoryID = selectedCategoryID,
                                               let category = tagCategories.first(where: { $0.id == categoryID }) {
                                                Text(category.name)
                                            } else {
                                                Text("no_category".localized)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(UIColor.systemBackground))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                                
                                // 管理分类链接
                                NavigationLink(destination: TagCategoryListView()) {
                                    HStack {
                                        Image(systemName: "folder.badge.plus")
                                            .foregroundColor(.blue)
                                        Text("manage_categories".localized)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.systemBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        
                        // 颜色选择
                        VStack(spacing: 16) {
                            HStack {
                                Text("color".localized)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                            selectedColor = color
                                        }
                                        // 实时更新标签颜色，确保预览能立即反映变化
                                        if !editedTag.isEmpty {
                                            TagColorManager.shared.setColor(color, for: editedTag)
                                        }
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                            .scaleEffect(selectedColor == color ? 1.15 : 1.0)
                                            .shadow(color: selectedColor == color ? color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("edit_tag_title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("cancel".localized)
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveTag()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("save".localized)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
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
                    )
                }
                .disabled(editedTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(editedTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("alert_info_title".localized),
                message: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
        .onAppear {
            // 获取Tag对象信息
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == originalTag })
            if let existingTag = try? modelContext.fetch(descriptor).first {
                tagDescription = existingTag.tagDescription
                selectedCategoryID = existingTag.categoryID
            }
        }
    }
    
    // 保存标签方法
    private func saveTag() {
        let trimmedTag = editedTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTag.isEmpty {
            alertMessage = "tag_name_empty".localized
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
            alertMessage = "save_failed".localized + ": \(error.localizedDescription)"
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