//
//  ImprovementDetailView.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import SwiftUI
import SwiftData

struct ImprovementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 待改进项列表
    @Query private var improvements: [Improvement]
    
    // 编辑状态
    @State private var isEditing = false
    @State private var showingAddSheet = false
    @State private var newImprovement = Improvement(emoji: "📝", name: "", description: "", priority: .medium)
    
    // 选中的优先级筛选
    @State private var selectedPriority: Priority? = nil
    
    // 改进项统计
    private var highPriorityCount: Int {
        improvements.filter { $0.priority == .high }.count
    }
    
    private var mediumPriorityCount: Int {
        improvements.filter { $0.priority == .medium }.count
    }
    
    private var lowPriorityCount: Int {
        improvements.filter { $0.priority == .low }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 待改进项统计卡片
                        improvementStatsCard
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // 优先级筛选器
                        prioritySelector
                            .padding(.horizontal)
                        
                        // 待改进项列表
                        improvementList
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("待改进项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "完成" : "编辑") {
                        isEditing.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addImprovementView
            }
        }
    }
    
    // 待改进项统计卡片
    private var improvementStatsCard: some View {
        VStack(spacing: 16) {
            // 待改进项总数
            VStack(spacing: 8) {
                Text("待改进项总数")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Text("\(improvements.count)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.systemOrange))
            }
            
            // 优先级分布
            HStack(spacing: 0) {
                // 高优先级
                VStack(spacing: 6) {
                    Text("高优先级")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text("\(highPriorityCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.systemRed))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 1, height: 36)
                
                // 中优先级
                VStack(spacing: 6) {
                    Text("中优先级")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text("\(mediumPriorityCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.systemOrange))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 1, height: 36)
                
                // 低优先级
                VStack(spacing: 6) {
                    Text("低优先级")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text("\(lowPriorityCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.systemBlue))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 优先级选择器
    private var prioritySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部优先级按钮
                priorityButton(nil)
                
                // 各个优先级按钮
                priorityButton(.high)
                priorityButton(.medium)
                priorityButton(.low)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
    
    // 优先级按钮
    private func priorityButton(_ priority: Priority?) -> some View {
        Button(action: {
            withAnimation {
                selectedPriority = priority
            }
        }) {
            HStack(spacing: 6) {
                if let priority = priority {
                    Circle()
                        .fill(priorityColor(priority))
                        .frame(width: 8, height: 8)
                }
                
                Text(priority?.rawValue ?? "全部")
                    .font(.subheadline)
                    .fontWeight(selectedPriority == priority ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedPriority == priority ? (priority != nil ? priorityColor(priority!) : Color.gray).opacity(0.2) : Color(UIColor.systemGray6))
            .foregroundColor(selectedPriority == priority ? (priority != nil ? priorityColor(priority!) : Color.gray) : Color(UIColor.label))
            .cornerRadius(16)
        }
    }
    
    // 待改进项列表
    private var improvementList: some View {
        let filteredImprovements = improvements
            .filter { improvement in
                // 根据优先级筛选
                selectedPriority == nil || improvement.priority == selectedPriority
            }
        
        return VStack(spacing: 0) {
            ForEach(filteredImprovements.indices, id: \.self) { index in
                improvementRow(improvement: filteredImprovements[index])
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            
            if isEditing {
                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(UIColor.systemOrange))
                        Text("添加待改进项")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(UIColor.systemOrange))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.systemOrange).opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 8)
    }
    
    // 待改进项行视图
    private func improvementRow(improvement: Improvement) -> some View {
        HStack(spacing: 12) {
            // Emoji图标
            Text(improvement.emoji)
                .font(.title)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(improvement.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // 优先级标签
                    priorityLabel(improvement.priority)
                }
                
                Text(improvement.description)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(2)
            }
            
            if isEditing {
                Menu {
                    Button(role: .destructive, action: {
                        modelContext.delete(improvement)
                    }) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    // 优先级标签
    private func priorityLabel(_ priority: Priority) -> some View {
        Text(priority.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor(priority).opacity(0.2))
            .foregroundColor(priorityColor(priority))
            .cornerRadius(4)
    }
    
    // 优先级颜色
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return Color.orange
        case .low:
            return Color.blue
        }
    }
    
    // 添加待改进项视图
    private var addImprovementView: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $newImprovement.name)
                    
                    HStack {
                        Text("图标")
                        Spacer()
                        TextField("选择图标", text: $newImprovement.emoji)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("优先级", selection: $newImprovement.priority) {
                        ForEach(Priority.allCases, id: \.self) {
                            priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("详细描述")) {
                    TextEditor(text: $newImprovement.description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("添加待改进项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingAddSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !newImprovement.name.isEmpty {
                            modelContext.insert(newImprovement)
                            showingAddSheet = false
                            newImprovement = Improvement(emoji: "📝", name: "", description: "", priority: .medium)
                        }
                    }
                    .disabled(newImprovement.name.isEmpty)
                }
            }
        }
    }
    
    // 删除待改进项
    @Environment(\.modelContext) private var modelContext

    private func deleteImprovement(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(improvements[index])
        }
    }
    
    // 移动待改进项
    private func moveImprovement(from source: IndexSet, to destination: Int) {
        // SwiftData 暂不支持直接移动，需要手动删除再插入
        var movedImprovements: [Improvement] = improvements
        movedImprovements.move(fromOffsets: source, toOffset: destination)
        // 这里需要更复杂的逻辑来处理 SwiftData 的顺序，或者重新排序查询结果
        // 对于简单的列表，可以考虑重新加载或根据排序键处理
    }
}

// 待改进项模型
@Model
class Improvement: Identifiable {
    var id = UUID()
    var emoji: String
    var name: String
    var description: String
    var priority: Priority

    init(id: UUID = UUID(), emoji: String, name: String, description: String, priority: Priority) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.description = description
        self.priority = priority
    }
}

// 优先级枚举
enum Priority: String, Codable, CaseIterable {
    case high = "高"
    case medium = "中"
    case low = "低"
}

#Preview {
    ImprovementDetailView()
}