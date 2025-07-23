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
    @State private var improvements = [
        Improvement(emoji: "📱", name: "减少手机使用", description: "每天使用手机时间超过5小时，需要减少使用时间", priority: .high),
        Improvement(emoji: "🍔", name: "改善饮食习惯", description: "减少垃圾食品摄入，增加蔬果摄入量", priority: .medium),
        Improvement(emoji: "🛌", name: "规律作息", description: "保持每天11点前睡觉，7点起床的作息习惯", priority: .high),
        Improvement(emoji: "🎮", name: "控制游戏时间", description: "周末游戏时间不超过3小时", priority: .low),
        Improvement(emoji: "💤", name: "午休习惯", description: "工作日午休不超过30分钟", priority: .medium)
    ]
    
    // 编辑状态
    @State private var isEditing = false
    @State private var showingAddSheet = false
    @State private var newImprovement = Improvement(emoji: "📝", name: "", description: "", priority: .medium)
    
    var body: some View {
        NavigationStack {
            List {
                // 待改进项列表
                ForEach(improvements.indices, id: \.self) { index in
                    improvementRow(improvement: improvements[index])
                }
                .onDelete(perform: deleteImprovement)
                .onMove(perform: moveImprovement)
                
                if isEditing {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Label("添加待改进项", systemImage: "plus.circle")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("待改进项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "完成" : "编辑") {
                        isEditing.toggle()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                if isEditing {
                    ToolbarItem(placement: .bottomBar) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addImprovementView
            }
        }
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
        }
        .padding(.vertical, 8)
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
                        Text("高").tag(Priority.high)
                        Text("中").tag(Priority.medium)
                        Text("低").tag(Priority.low)
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
                            improvements.append(newImprovement)
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
    private func deleteImprovement(at offsets: IndexSet) {
        improvements.remove(atOffsets: offsets)
    }
    
    // 移动待改进项
    private func moveImprovement(from source: IndexSet, to destination: Int) {
        improvements.move(fromOffsets: source, toOffset: destination)
    }
}

// 待改进项模型
struct Improvement: Identifiable {
    var id = UUID()
    var emoji: String
    var name: String
    var description: String
    var priority: Priority
}

// 优先级枚举
enum Priority: String {
    case high = "高"
    case medium = "中"
    case low = "低"
}

#Preview {
    ImprovementDetailView()
}