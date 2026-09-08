import SwiftUI
import SwiftData

// 可复用的标签添加弹窗：支持从标签库选择（含搜索）或创建新标签
struct AddTagSheet: View {
    // 当前实体已有的标签（用于禁用重复添加）
    let existingEntityTags: [String]
    // 添加回调：返回本次新增的标签列表（去重后）
    let onAddTags: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var contacts: [Contact]
    @Query private var users: [User]
    @Query private var tagObjects: [Tag]

    @ObservedObject private var tagColorManager = TagColorManager.shared

    @State private var searchText: String = ""
    @State private var selectedNames: Set<String> = []
    @State private var newTagName: String = ""
    @State private var errorMessage: String? = nil
    
    // 标签分类相关状态
    @State private var showingCategoryManagement = false
    @Query private var tagCategories: [TagCategory]
    @State private var selectedCategory: TagCategory?

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // 汇总全局标签库（内置标签 + 已绑定的标签）并去重，过滤掉未绑定的空标签
    private var allTags: [String] {
        var map: [String: String] = [:] // normalized -> display name
        var usedTags: Set<String> = [] // 记录实际被使用的标签

        // 收集所有已使用的标签
        // 目标使用的标签
        for g in goals where !g.isDeleted {
            for name in g.tags {
                let n = normalize(name)
                usedTags.insert(n)
                if map[n] == nil { map[n] = name }
            }
        }

        // 联系人使用的标签
        for c in contacts where !c.isDeleted {
            for name in c.tags {
                let n = normalize(name)
                usedTags.insert(n)
                if map[n] == nil { map[n] = name }
            }
        }

        // 用户使用的标签
        for u in users {
            for name in u.tags {
                let n = normalize(name)
                usedTags.insert(n)
                if map[n] == nil { map[n] = name }
            }
        }

        // 内置标签优先加入（不管是否被使用都显示）
        for name in BuiltInTags.allNames {
            map[normalize(name)] = name
        }

        // 只保留已使用的Tag对象（除了内置标签）
        for t in tagObjects {
            let n = normalize(t.name)
            // 如果是内置标签或者已被使用，则保留
            if BuiltInTags.isBuiltIn(t.name) || usedTags.contains(n) {
                if map[n] == nil { map[n] = t.name }
            }
        }

        var filtered = Array(map.values)
        
        // 搜索文本过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        // 分类过滤：如果选中了分类，则只保留该分类下的标签
        if let selectedCategory = selectedCategory {
            // 获取该分类下的所有标签对象
            let categoryTagObjects = tagObjects.filter { $0.categoryID == selectedCategory.id }
            let categoryTagNames = Set(categoryTagObjects.map { normalize($0.name) })
            // 内置标签始终显示，其他标签需属于该分类
            filtered = filtered.filter { name in
                BuiltInTags.isBuiltIn(name) || categoryTagNames.contains(normalize(name))
            }
        }
        
        return filtered.sorted()
    }

    private func canAddSelection() -> Bool {
        let already = Set(existingEntityTags.map(normalize))
        let adding = Set(selectedNames.map(normalize))
        return !adding.subtracting(already).isEmpty
    }

    private func validateNewName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil } // 空名称不显示错误，只是禁用按钮
        if trimmed.count > 32 { return "tag_name_too_long".localized }
        // 禁止与内置标签重复
        if BuiltInTags.isBuiltIn(trimmed) { return "tag_name_is_built_in".localized }
        // 全局重复检查
        let n = normalize(trimmed)
        let global = Set(allTags.map(normalize))
        if global.contains(n) { return "tag_already_exists".localized }
        return nil
    }

    private func commitSelection() {
        // 过滤掉已存在于实体的标签，避免重复添加
        let existingSet = Set(existingEntityTags.map(normalize))
        let pickedArray = Array(selectedNames.filter { !existingSet.contains(normalize($0)) })
        guard !pickedArray.isEmpty else { dismiss(); return }
        onAddTags(pickedArray)
        dismiss()
    }

    private func commitNewTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let err = validateNewName(name) {
            errorMessage = err
            return
        }
        // 新建标签默认颜色：蓝色（并写入到颜色管理器与Tag对象）
        TagColorManager.shared.setColor(.blue, for: name)
        let tag = Tag(
            name: name,
            tagDescription: "",
            color: Color.blue.toHex(),
            categoryID: nil
        )
        modelContext.insert(tag)
        // 回调添加到实体
        onAddTags([name])
        // 清理状态
        newTagName = ""
        searchText = ""
        errorMessage = nil
    }

    private func tagColor(_ name: String) -> Color {
        TagColorManager.shared.getColor(for: name)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统一的标签输入区域（创建新标签 + 搜索）
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("search_or_create_tag_placeholder".localized, text: $newTagName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: newTagName) { _, newValue in
                                // 输入时自动更新搜索文本
                                searchText = newValue
                            }
                        if !newTagName.isEmpty {
                            Button(action: { 
                                newTagName = ""
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                    
                    // 显示创建新标签按钮（当输入内容有效时）
                    if let validationError = validateNewName(newTagName) {
                        // 如果有验证错误且不是空内容，显示错误信息
                        if !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(validationError)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    } else if !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // 如果内容有效且不为空，显示创建按钮
                        Button(action: { 
                            commitNewTag() 
                            dismiss() // 立即关闭弹窗
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                Text("create_and_add".localized)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(Color.blue)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

                Divider()
                    .padding(.vertical, 8)

                // 标签列表区域
                VStack(spacing: 0) {

                    // 可选择标签列表（多选）
                    List {
                        ForEach(allTags, id: \.self) { name in
                            Button(action: {
                                if selectedNames.contains(name) {
                                    selectedNames.remove(name)
                                } else {
                                    selectedNames.insert(name)
                                }
                            }) {
                                HStack(spacing: 14) {
                                    // 标签颜色圆圈，添加选中状态效果
                                    ZStack {
                                        Circle()
                                            .fill(tagColor(name))
                                            .frame(width: 10, height: 10)
                                        
                                        if selectedNames.contains(name) {
                                            Circle()
                                                .stroke(Color.blue, lineWidth: 2)
                                                .frame(width: 16, height: 16)
                                                .scaleEffect(selectedNames.contains(name) ? 1.0 : 0.8)
                                                .animation(.easeInOut(duration: 0.2), value: selectedNames.contains(name))
                                        }
                                    }
                                    .frame(width: 18, height: 18) // 固定容器大小
                                    
                                    Text(name)
                                        .font(.system(size: 16, weight: selectedNames.contains(name) ? .semibold : .regular))
                                        .foregroundColor(selectedNames.contains(name) ? .blue : .primary)
                                        .animation(.easeInOut(duration: 0.15), value: selectedNames.contains(name))
                                    
                                    Spacer()
                                    
                                    // 已有标签标识
                                    if existingEntityTags.contains(where: { normalize($0) == normalize(name) }) {
                                        Text("existing".localized)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color(UIColor.systemGray5))
                                            )
                                    }
                                    
                                    // 选中状态图标
                                    if selectedNames.contains(name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 16))
                                            .scaleEffect(selectedNames.contains(name) ? 1.0 : 0.8)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedNames.contains(name))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .contentShape(Rectangle())
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedNames.contains(name) ? Color.blue.opacity(0.08) : Color(UIColor.secondarySystemBackground))
                                    .animation(.easeInOut(duration: 0.2), value: selectedNames.contains(name))
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 8)
                
                // 标签分类管理区域
                VStack(spacing: 12) {
                    // 移除顶部分隔线，保持界面简洁
                    
                    // 分类管理标题（移除右上角“管理”按钮）
                    HStack {
                        Text("tag_category_management".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // 分类选择器（仅当有分类时显示）
                    if !tagCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "全部分类"选项
                                Button(action: {
                                    selectedCategory = nil
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.grid.2x2")
                                            .font(.system(size: 12))
                                        Text("all_categories".localized)
                                            .font(.system(size: 13))
                                    }
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == nil ? Color.blue : Color(UIColor.systemGray5))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 各个分类选项
                                ForEach(tagCategories, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color(hex: category.color) ?? .gray)
                                                .frame(width: 8, height: 8)
                                            Text(category.id == BuiltInTags.systemCategoryID ? BuiltInTags.systemCategoryLocalizedName : category.name)
                                                .font(.system(size: 13))
                                        }
                                        .foregroundColor(selectedCategory?.id == category.id ? .white : .primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory?.id == category.id ? Color.blue : Color(UIColor.systemGray5))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .padding(.horizontal, 8)
                )
            }
            .navigationBarTitle("add_tag_action".localized, displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("cancel".localized)
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                },
                trailing: Button(action: {
                    commitSelection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("add".localized)
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
                                        Color.blue,
                                        Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .disabled(!canAddSelection())
                .opacity(!canAddSelection() ? 0.6 : 1.0)
            )
            .sheet(isPresented: $showingCategoryManagement) {
                TagCategoryListView()
            }
        }
    }
}