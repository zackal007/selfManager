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
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(categories) { category in
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
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("标签分类")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
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
    
    // 添加按钮视图
    private var addButtonView: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16, weight: .semibold))
            Text("添加")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
                        // 图标和标题
                        VStack(spacing: 12) {
                            Image(systemName: "folder.circle.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(newCategoryColor)
                            
                            Text("添加新分类")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
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
                                                    .stroke(newCategoryName.isEmpty ? Color.clear : newCategoryColor, lineWidth: 2)
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
                                                    .stroke(newCategoryDescription.isEmpty ? Color.clear : newCategoryColor.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 颜色选择区域
                    VStack(spacing: 16) {
                        HStack {
                            Text("选择颜色")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: {
                                    newCategoryColor = color
                                }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(newCategoryColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: newCategoryColor == color ? 2 : 0)
                                        )
                                        .scaleEffect(newCategoryColor == color ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: newCategoryColor)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("添加分类")
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
                                            newCategoryColor,
                                            newCategoryColor.opacity(0.8)
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
                color: newCategoryColor.toHex() ?? "#0000FF"
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
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部预览区域
                    VStack(spacing: 24) {
                        // 分类预览
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: selectedColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 4) {
                                Text(editedName.isEmpty ? "分类名称" : editedName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                if !editedDescription.isEmpty {
                                    Text(editedDescription)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
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
                                                    .stroke(editedName.isEmpty ? Color.clear : selectedColor, lineWidth: 2)
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
                                                    .stroke(editedDescription.isEmpty ? Color.clear : selectedColor.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 颜色选择区域
                    VStack(spacing: 16) {
                        HStack {
                            Text("选择颜色")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
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
                                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("编辑分类")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
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
                                            selectedColor,
                                            selectedColor.opacity(0.8)
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
        category.color = selectedColor.toHex() ?? "#0000FF"
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
}

#Preview {
    TagCategoryListView()
}