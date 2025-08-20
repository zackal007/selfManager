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
    
    // 可选的标签颜色
    private let colorOptions: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .mint, .cyan, .red
    ]
    
    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink(destination: TagCategoryEditView(category: category)) {
                    HStack {
                        Circle()
                            .fill(Color(hex: category.color) ?? .blue)
                            .frame(width: 16, height: 16)
                        
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .font(.headline)
                            
                            if !category.categoryDescription.isEmpty {
                                Text(category.categoryDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("标签分类")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            addCategoryView
        }
    }
    
    // 添加分类视图
    private var addCategoryView: some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $newCategoryName)
                    TextField("分类描述（可选）", text: $newCategoryDescription)
                }
                
                Section(header: Text("分类颜色")) {
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
            }
            .navigationTitle("添加分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingAddCategory = false
                        resetNewCategoryFields()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        addCategory()
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // 添加分类方法
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty {
            let newCategory = TagCategory(
                name: trimmedName,
                categoryDescription: newCategoryDescription,
                color: selectedColor.toHex() ?? "#0000FF"
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
        Form {
            Section(header: Text("分类信息")) {
                TextField("分类名称", text: $editedName)
                TextField("分类描述（可选）", text: $editedDescription)
            }
            
            Section(header: Text("分类颜色")) {
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
            
            Section {
                Button("保存更改") {
                    saveCategory()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("编辑分类")
        .navigationBarTitleDisplayMode(.inline)
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