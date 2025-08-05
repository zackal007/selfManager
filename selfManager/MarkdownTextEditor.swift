//
//  MarkdownTextEditor.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import SwiftData
import Foundation

// Markdown链接类型
enum LinkType: String, CaseIterable {
    case goal = "goal"
    case contact = "contact"
    case record = "record"
    
    var displayName: String {
        switch self {
        case .goal: return "目标"
        case .contact: return "人脉"
        case .record: return "记录"
        }
    }
    
    var iconName: String {
        switch self {
        case .goal: return "target"
        case .contact: return "person.fill"
        case .record: return "doc.text.fill"
        }
    }
}

// 链接数据结构
struct LinkItem: Identifiable {
    let id: UUID
    let name: String
    let type: LinkType
    
    var markdownText: String {
        return "[\(name)](\(type.rawValue)://\(id.uuidString))"
    }
}

// Markdown文本编辑器
struct MarkdownTextEditor: View {
    @Binding var text: String
    @State private var showLinkSelector = false
    @State private var selectedLinkType: LinkType = .goal
    @State private var searchText = ""
    @State private var cursorPosition: Int = 0
    @State private var isPreviewMode = false
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]
    @Query private var allContacts: [Contact]
    @Query private var allRecords: [Record]
    
    let minHeight: CGFloat
    let onLinkTapped: ((LinkType, UUID) -> Void)?
    
    init(text: Binding<String>, minHeight: CGFloat = 200, onLinkTapped: ((LinkType, UUID) -> Void)? = nil) {
        self._text = text
        self.minHeight = minHeight
        self.onLinkTapped = onLinkTapped
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 工具栏
            HStack {
                Text("支持Markdown格式")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 预览模式切换按钮
                Button(action: {
                    withAnimation {
                        isPreviewMode.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isPreviewMode ? "pencil" : "eye")
                        Text(isPreviewMode ? "编辑" : "预览")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                if !isPreviewMode {
                    Button(action: {
                        showLinkSelector = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                            Text("插入链接")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // 文本编辑器或预览
            if isPreviewMode {
                MarkdownDisplayView(text: text, onLinkTapped: onLinkTapped)
                    .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
                    .padding(8)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: minHeight)
                        .padding(8)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if text.isEmpty {
                        Text("在这里输入内容...\n\n支持Markdown格式：\n- **粗体**\n- *斜体*\n- [链接](url)\n- 通过工具栏插入目标、人脉链接")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
            }
            
            // Markdown预览提示
            if containsMarkdownLinks(text) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("包含链接，点击可跳转到相关内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showLinkSelector) {
            LinkSelectorView(
                selectedType: $selectedLinkType,
                searchText: $searchText,
                onLinkSelected: { linkItem in
                    insertLink(linkItem)
                    showLinkSelector = false
                }
            )
        }
    }
    
    // 检查文本是否包含Markdown链接
    private func containsMarkdownLinks(_ text: String) -> Bool {
        let pattern = "\\[.*?\\]\\(.*?\\)"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    // 插入链接
    private func insertLink(_ linkItem: LinkItem) {
        let linkText = linkItem.markdownText
        
        // 如果有选中的文本，替换选中的文本
        // 否则在当前光标位置插入
        if text.isEmpty {
            text = linkText
        } else {
            text += " " + linkText
        }
    }
}

// 链接选择器视图
struct LinkSelectorView: View {
    @Binding var selectedType: LinkType
    @Binding var searchText: String
    let onLinkSelected: (LinkItem) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allGoals: [Goal]
    @Query private var allContacts: [Contact]
    @Query private var allRecords: [Record]
    
    var filteredItems: [LinkItem] {
        var items: [LinkItem] = []
        
        switch selectedType {
        case .goal:
            items = allGoals.compactMap { goal in
                LinkItem(id: goal.id, name: goal.name, type: .goal)
            }
        case .contact:
            items = allContacts.compactMap { contact in
                LinkItem(id: contact.id, name: contact.name, type: .contact)
            }
        case .record:
            items = allRecords.compactMap { record in
                LinkItem(id: record.id, name: record.title, type: .record)
            }
        }
        
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 类型选择器
                Picker("链接类型", selection: $selectedType) {
                    ForEach(LinkType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.iconName)
                            Text(type.displayName)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索\(selectedType.displayName)", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // 项目列表
                List(filteredItems) { item in
                    Button(action: {
                        onLinkSelected(item)
                    }) {
                        HStack {
                            Image(systemName: item.type.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(item.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
                
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedType.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("没有找到\(selectedType.displayName)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("还没有创建任何\(selectedType.displayName)")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("尝试使用不同的搜索关键词")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("插入链接")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Markdown渲染视图（用于显示带链接的文本）
struct MarkdownDisplayView: View {
    let text: String
    let onLinkTapped: ((LinkType, UUID) -> Void)?
    
    init(text: String, onLinkTapped: ((LinkType, UUID) -> Void)? = nil) {
        self.text = text
        self.onLinkTapped = onLinkTapped
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(parseMarkdownText(text), id: \.id) { element in
                    switch element {
                    case .text(let content):
                        Text(content)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                    case .link(let title, let url):
                        if let linkInfo = parseLinkURL(url) {
                            Button(action: {
                                onLinkTapped?(linkInfo.type, linkInfo.id)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: linkInfo.type.iconName)
                                        .font(.caption)
                                    Text(title)
                                        .underline()
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Link(title, destination: URL(string: url) ?? URL(string: "https://example.com")!)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
    
    // 解析链接URL
    private func parseLinkURL(_ url: String) -> (type: LinkType, id: UUID)? {
        for linkType in LinkType.allCases {
            let prefix = "\(linkType.rawValue)://"
            if url.hasPrefix(prefix) {
                let idString = String(url.dropFirst(prefix.count))
                if let uuid = UUID(uuidString: idString) {
                    return (type: linkType, id: uuid)
                }
            }
        }
        return nil
    }
}

// Markdown元素类型
enum MarkdownElement {
    case text(String)
    case link(title: String, url: String)
    
    var id: String {
        switch self {
        case .text(let content):
            return "text_\(content.hashValue)"
        case .link(let title, let url):
            return "link_\(title)_\(url)"
        }
    }
}

// 解析Markdown文本
func parseMarkdownText(_ text: String) -> [MarkdownElement] {
    var elements: [MarkdownElement] = []
    let pattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
    
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        var lastEnd = 0
        
        for match in matches {
            // 添加链接前的文本
            if match.range.location > lastEnd {
                let startIndex = text.index(text.startIndex, offsetBy: lastEnd)
                let endIndex = text.index(text.startIndex, offsetBy: match.range.location)
                let beforeText = String(text[startIndex..<endIndex])
                if !beforeText.isEmpty {
                    elements.append(.text(beforeText))
                }
            }
            
            // 添加链接
            if let titleRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text) {
                let title = String(text[titleRange])
                let url = String(text[urlRange])
                elements.append(.link(title: title, url: url))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // 添加最后的文本
        if lastEnd < text.count {
            let startIndex = text.index(text.startIndex, offsetBy: lastEnd)
            let remainingText = String(text[startIndex...])
            if !remainingText.isEmpty {
                elements.append(.text(remainingText))
            }
        }
        
        // 如果没有找到任何链接，返回整个文本
        if elements.isEmpty && !text.isEmpty {
            elements.append(.text(text))
        }
        
    } catch {
        // 如果正则表达式失败，返回原始文本
        elements.append(.text(text))
    }
    
    return elements
}

#Preview {
    MarkdownTextEditor(text: .constant("这是一个示例文本，包含[目标链接](goal://123e4567-e89b-12d3-a456-426614174000)和**粗体**文字。"))
        .padding()
}