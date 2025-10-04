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

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // 汇总全局标签库（内置标签 + Tag对象 + 目标/联系人/用户中使用的标签）并去重
    private var allTags: [String] {
        var map: [String: String] = [:] // normalized -> display name

        // 内置标签优先加入（保证显示）
        for name in BuiltInTags.allNames {
            map[normalize(name)] = name
        }

        // 数据库中的Tag对象
        for t in tagObjects {
            let n = normalize(t.name)
            if map[n] == nil { map[n] = t.name }
        }

        // 目标使用的标签
        for g in goals where !g.isDeleted {
            for name in g.tags {
                let n = normalize(name)
                if map[n] == nil { map[n] = name }
            }
        }

        // 联系人使用的标签
        for c in contacts where !c.isDeleted {
            for name in c.tags {
                let n = normalize(name)
                if map[n] == nil { map[n] = name }
            }
        }

        // 用户使用的标签
        for u in users {
            for name in u.tags {
                let n = normalize(name)
                if map[n] == nil { map[n] = name }
            }
        }

        let all = Array(map.values)
        if searchText.isEmpty { return all.sorted() }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
    }

    private func canAddSelection() -> Bool {
        let already = Set(existingEntityTags.map(normalize))
        let adding = Set(selectedNames.map(normalize))
        return !adding.subtracting(already).isEmpty
    }

    private func validateNewName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "标签名称不能为空" }
        if trimmed.count > 32 { return "标签名称长度不应超过 32 个字符" }
        // 禁止与内置标签重复
        if BuiltInTags.isBuiltIn(trimmed) { return "该标签为系统内置标签，请从列表中选择" }
        // 全局重复检查
        let n = normalize(trimmed)
        let global = Set(allTags.map(normalize))
        if global.contains(n) { return "该标签已存在，请在列表中选择" }
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
        // 清理状态并关闭
        newTagName = ""
        errorMessage = nil
        dismiss()
    }

    private func tagColor(_ name: String) -> Color {
        TagColorManager.shared.getColor(for: name)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索与选择区域
                VStack(spacing: 12) {
                    // 区块标题
                    HStack {
                        Text("从标签库选择")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索标签", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))

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
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(tagColor(name))
                                        .frame(width: 10, height: 10)
                                    Text(name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if existingEntityTags.contains(where: { normalize($0) == normalize(name) }) {
                                        Text("已有")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if selectedNames.contains(name) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Divider()
                    .padding(.vertical, 8)

                // 创建新标签区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("创建新标签")
                        .font(.system(size: 16, weight: .semibold))
                    HStack(spacing: 8) {
                        TextField("输入新标签名称", text: $newTagName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: { commitNewTag() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("创建并添加")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(Color.blue)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(validateNewName(newTagName) != nil)
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                        Text("新标签默认颜色：蓝色")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let msg = validateNewName(newTagName) {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .navigationBarTitle("添加标签", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("添加") { commitSelection() }.disabled(!canAddSelection())
            )
        }
    }
}