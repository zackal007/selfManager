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
    
    let originalTag: String
    let tagType: TagsView.TagType
    
    @State private var editedTag: String
    @State private var selectedColor: Color
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
            Form {
                // 标签名称编辑
                Section(header: Text("标签名称")) {
                    TextField("标签名称", text: $editedTag)
                        .padding(.vertical, 8)
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
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 预览
                Section(header: Text("预览")) {
                    HStack {
                        Text(editedTag)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedColor.opacity(0.1))
                            .cornerRadius(16)
                        
                        Spacer()
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
        
        if trimmedTag != originalTag {
            // 更新标签名称
            TagColorManager.shared.updateTagName(from: originalTag, to: trimmedTag)
            // 更新所有使用此标签的项目
            updateTagInEntities()
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