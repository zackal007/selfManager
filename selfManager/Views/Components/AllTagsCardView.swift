//
//  AllTagsCardView.swift
//  selfManager
//
//  Created by Assistant on 2025/1/17.
//

import SwiftUI
import SwiftData

// 全部标签卡片视图
struct AllTagsCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var contacts: [Contact]
    @Query private var users: [User]
    @ObservedObject private var tagColorManager = TagColorManager.shared
    
    @Binding var showingTagsView: Bool
    
    // 获取所有标签
    private func getAllTags() -> [String] {
        var tags = Set<String>()
        
        // 收集目标标签
        for goal in goals where !goal.isDeleted {
            for tag in goal.tags {
                tags.insert(tag)
            }
        }
        
        // 收集联系人标签
        for contact in contacts {
            for tag in contact.tags {
                tags.insert(tag)
            }
        }
        
        // 收集用户标签
        for user in users {
            for tag in user.tags {
                tags.insert(tag)
            }
        }
        
        return Array(tags).sorted()
    }
    
    // 计算使用标签的项目数量
    private func countItemsWithTag(_ tag: String) -> Int {
        var count = 0
        
        // 计算目标中的标签使用
        for goal in goals where !goal.isDeleted {
            if goal.tags.contains(tag) {
                count += 1
            }
        }
        
        // 计算联系人中的标签使用
        for contact in contacts {
            if contact.tags.contains(tag) {
                count += 1
            }
        }
        
        // 计算用户中的标签使用
        for user in users {
            if user.tags.contains(tag) {
                count += 1
            }
        }
        
        return count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和查看全部按钮
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("全部标签")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    
                    let allTags = getAllTags()
                    Text("共\(allTags.count)个标签")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                Button("查看全部") {
                    showingTagsView = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(UIColor.systemBlue))
            }
            
            // 标签列表
            let allTags = getAllTags()
            if allTags.isEmpty {
                // 空状态
                VStack(spacing: 8) {
                    Image(systemName: "tag")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    
                    Text("暂无标签")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text("创建目标或联系人时可以添加标签")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // 标签列表 - 每行一个标签
                VStack(spacing: 8) {
                    ForEach(Array(allTags.prefix(6).enumerated()), id: \.offset) { index, tag in
                        HStack(spacing: 12) {
                            // 标签颜色指示器
                            Circle()
                                .fill(tagColorManager.getColor(for: tag))
                                .frame(width: 8, height: 8)
                            
                            // 标签名称
                            Text(tag)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                            
                            // 使用数量
                            let count = countItemsWithTag(tag)
                            Text("\(count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(UIColor.systemGray6))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemBackground))
                        )
                    }
                    
                    // 如果标签数量超过6个，显示更多提示
                    if allTags.count > 6 {
                        Button(action: {
                            showingTagsView = true
                        }) {
                            HStack {
                                Text("还有\(allTags.count - 6)个标签")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemBlue).opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    AllTagsCardView(showingTagsView: .constant(false))
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
}