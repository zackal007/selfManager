//
//  TagCategoryListView.swift
//  selfManager
//
//  Created by Trae AI on 2024/12/31.
//

import SwiftUI
import SwiftData

struct TagCategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [TagCategory]
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryDescription = ""
    @State private var selectedColor: Color = .blue
    @State private var newCategoryColor: Color = .blue
    
    // 可选的标签颜色
    private let colorOptions: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .mint, .cyan, .red
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(categories.filter { $0.name != "系统内置" }) { category in
                    NavigationLink(destination: TagCategoryEditView(category: category)) {
                        categoryRowView(for: category)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: deleteCategories)
            }
            
            Spacer(minLength: 100)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("标签分类")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddCategory = true
                }) {
                    addButtonView
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            addCategoryView
        }
    }
    
    // 分离出来的分类行视图
    private func categoryRowView(for category: TagCategory) -> some View {
        HStack(spacing: 16) {
            // 分类颜色指示器
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: category.color) ?? .blue)
                .frame(width: 6, height: 60)
            
            // 分类信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 标签数量徽章
                    tagCountBadge
                }
                
                if !category.categoryDescription.isEmpty {
                    Text(category.categoryDescription)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("暂无描述")
                        .font(.system(size: 15))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .italic()
                }
            }
            
            // 箭头指示器
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // 标签数量徽章
    private var tagCountBadge: some View {
        Text("0")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
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
    
    // 添加按钮视图 - 优化大小和边距
    private var addButtonView: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("添加")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
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
    
    // 添加分类视图 - 优化设计
    private var addCategoryView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部区域
                    VStack(spacing: 24) {
                        // 图标
                        VStack(spacing: 12) {
                            Image(systemName: "folder.circle.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 32)
                        
                        // 输入框区域
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("分类名称")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("请输入分类名称", text: $newCategoryName)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(newCategoryName.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                                            )
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("分类描述（可选）")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("请输入分类描述", text: $newCategoryDescription)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(newCategoryDescription.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("添加标签分类")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAddCategory = false
                        resetNewCategoryFields()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("取消")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        addCategory()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("保存")
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
                                            Color.blue,
                                            Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // 添加分类方法
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty {
            let newCategory = TagCategory(
                name: trimmedName,
                categoryDescription: newCategoryDescription,
                color: "#007AFF"  // 默认使用iOS系统蓝色
            )
            
            modelContext.insert(newCategory)
            
            do {
                try modelContext.save()
                resetNewCategoryFields()
                showingAddCategory = false
            } catch {
                print("Failed to save category: \(error)")
            }
        }
    }
    
    // 重置新分类字段
    private func resetNewCategoryFields() {
        newCategoryName = ""
        newCategoryDescription = ""
        selectedColor = .blue
        newCategoryColor = .blue
    }
    
    // 删除分类
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            
            // 更新使用此分类的标签
            updateTagsForDeletedCategory(categoryID: category.id)
            
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete categories: \(error)")
        }
    }
    
    // 更新使用已删除分类的标签
    private func updateTagsForDeletedCategory(categoryID: UUID) {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.categoryID == categoryID })
        if let tagsWithCategory = try? modelContext.fetch(descriptor) {
            for tag in tagsWithCategory {
                tag.categoryID = nil
                tag.modifyTime = Date()
            }
        }
    }
}

// 标签分类编辑视图
struct TagCategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: TagCategory
    
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var selectedColor: Color
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    // 可选的标签颜色
    private let colorOptions: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .mint, .cyan, .red
    ]
    
    init(category: TagCategory) {
        self.category = category
        
        _editedName = State(initialValue: category.name)
        _editedDescription = State(initialValue: category.categoryDescription)
        _selectedColor = State(initialValue: Color(hex: category.color) ?? .blue)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 头部预览区域
                VStack(spacing: 24) {
                    // 分类预览
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // 删除重复的预览内容，只保留图标
                    }
                    .padding(.top, 32)
                    
                    // 输入框区域
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分类名称")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("请输入分类名称", text: $editedName)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(editedName.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                                        )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分类描述（可选）")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("请输入分类描述", text: $editedDescription)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(editedDescription.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
                

                
                Spacer(minLength: 100)
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // 删除按钮
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.systemGray6))
                            )
                    }
                    
                    // 保存按钮
                    Button(action: {
                        saveCategory()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("保存")
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
                                            Color.blue,
                                            Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("保存失败"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除分类\"\(editedName)\"吗？此操作不可撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteCategory()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
    
    // 保存分类方法
    private func saveCategory() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            alertMessage = "分类名称不能为空"
            showingSaveAlert = true
            return
        }
        
        // 更新分类
        category.name = trimmedName
        category.categoryDescription = editedDescription
        category.color = "#007AFF"  // 固定使用iOS系统蓝色
        category.modifyTime = Date()
        
        // 保存更改
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "保存失败: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
    
    // 删除分类方法
    private func deleteCategory() {
        // 更新使用此分类的标签
        updateTagsForDeletedCategory(categoryID: category.id)
        
        // 删除分类
        modelContext.delete(category)
        
        // 保存更改
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "删除失败: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
    
    // 更新使用已删除分类的标签
    private func updateTagsForDeletedCategory(categoryID: UUID) {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.categoryID == categoryID
            }
        )
        
        do {
            let tags = try modelContext.fetch(descriptor)
            for tag in tags {
                tag.categoryID = nil
                tag.modifyTime = Date()
            }
        } catch {
            print("更新标签分类失败: \(error)")
        }
    }
}

#Preview {
    TagCategoryListView()
}