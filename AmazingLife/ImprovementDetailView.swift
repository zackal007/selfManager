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
    @Environment(\.modelContext) private var modelContext
    
    // 待改进项列表
    @Query private var improvements: [Improvement]
    
    // 编辑状态
    @State private var isEditing = false
    @State private var showingAddSheet = false
    @State private var newImprovement = Improvement(emoji: "📝", name: "", improvementDescription: "", priority: .medium)
    
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
    private var highPriorityRatio: Double {
        let total = improvements.count
        return total > 0 ? Double(highPriorityCount) / Double(total) : 0.0
    }
    
    // 压力指数（基于优先级分布的权重）
    private var stressIndex: Double {
        let total = improvements.count
        guard total > 0 else { return 0 }
        let score = Double(highPriorityCount) * 1.0 + Double(mediumPriorityCount) * 0.6 + Double(lowPriorityCount) * 0.3
        return min(1.0, score / Double(total))
    }
    
    // 优先级分布（比例）
    private var priorityDistribution: [Double] {
        let total = max(1, improvements.count)
        return [
            Double(highPriorityCount) / Double(total),
            Double(mediumPriorityCount) / Double(total),
            Double(lowPriorityCount) / Double(total)
        ]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 焦虑统计（标题 + 概览卡）
                        Text("焦虑统计")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        improvementOverviewCard
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
            // 顶部压力指标与关键计数
            HStack(spacing: 12) {
                pressureGaugeRing
                
                VStack(spacing: 6) {
                    Text("总待办")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("\(improvements.count)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.systemOrange))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemOrange).opacity(0.08))
                .cornerRadius(DesignToken.cornerRadiusMedium)
                
                VStack(spacing: 6) {
                    Text("高优先")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("\(highPriorityCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.systemRed))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemRed).opacity(0.08))
                .cornerRadius(DesignToken.cornerRadiusMedium)
            }
            
            // 优先级分布（堆叠条图）
            VStack(alignment: .leading, spacing: 8) {
                Text("优先级分布")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                stackedDistributionBar(values: priorityDistribution)
                HStack(spacing: 12) {
                    legendDot("高", color: .red)
                    legendDot("中", color: .orange)
                    legendDot("低", color: .blue)
                }
                .font(.caption2)
                .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(DesignToken.cornerRadius)
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
            .cornerRadius(DesignToken.cornerRadius)
        }
    }
    
    // 待改进项列表
    private var improvementList: some View {
        let filteredImprovements = improvements
            .filter { improvement in
                // 根据优先级筛选
                selectedPriority == nil || improvement.priority == selectedPriority
            }
        
        return VStack(alignment: .leading, spacing: 10) {
            // 列表标题
            HStack {
                Text("焦虑列表")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(Color(UIColor.systemOrange))
                }
                .opacity(isEditing ? 1 : 0)
                .animation(.easeInOut, value: isEditing)
            }
            .padding(.horizontal)
            .padding(.top, 4)

            ForEach(filteredImprovements.indices, id: \.self) { index in
                improvementRow(improvement: filteredImprovements[index])
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(DesignToken.cornerRadiusMedium)
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
                    .cornerRadius(DesignToken.cornerRadiusMedium)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 8)
    }
    
    // 待改进项行视图
    private func improvementRow(improvement: Improvement) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Emoji图标
                Text(improvement.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(improvement.name)
                            .font(.headline)
                        Spacer()
                        priorityLabel(improvement.priority)
                    }
                    Text(improvement.improvementDescription)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                }
                Spacer()
            }
            
            // 线性进度：根据优先级映射权重（高100%，中60%，低30%）
            HStack {
                let pct: Double = {
                    switch improvement.priority {
                    case .high: return 1.0
                    case .medium: return 0.6
                    case .low: return 0.3
                    }
                }()
                Text({
                    switch improvement.priority {
                    case .high: return "高优 1.0"
                    case .medium: return "中优 0.6"
                    case .low: return "低优 0.3"
                    }
                }())
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            linearProgress(pct: {
                switch improvement.priority {
                case .high: return 1.0
                case .medium: return 0.6
                case .low: return 0.3
                }
            }(), color: priorityColor(improvement.priority))
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(DesignToken.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 优先级标签
    private func priorityLabel(_ priority: Priority) -> some View {
        Text(priority.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor(priority).opacity(0.2))
            .foregroundColor(priorityColor(priority))
            .cornerRadius(DesignToken.cornerRadiusBadge)
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
    
    // 压力指数环形仪表
    private var pressureGaugeRing: some View {
        let pct = stressIndex
        return ZStack {
            Circle()
                .stroke(Color(UIColor.systemGray5), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(pct))
                .stroke(Color(UIColor.systemRed), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("压力指数")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(DesignToken.cornerRadiusMedium)
    }
    
    // 优先级分布堆叠条图
private func stackedDistributionBar(values: [Double]) -> some View {
    let totalWidth: CGFloat = 220
    let colors: [Color] = [.red, .orange, .blue]
    return ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(UIColor.systemGray5))
            .frame(width: totalWidth, height: 12)
        HStack(spacing: 0) {
            ForEach(values.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: i == 0 ? 6 : 0)
                    .fill(colors[i])
                    .frame(width: max(0, totalWidth * CGFloat(values[i])), height: 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// 概览卡：左侧压力指数与线性进度，右侧高优待办数量与占比
private var improvementOverviewCard: some View {
    VStack(spacing: 12) {
        HStack(spacing: 16) {
            // 左侧：压力指数（0~1）
            VStack(alignment: .leading, spacing: 8) {
                Text("压力指数")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.0f", stressIndex * 100))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("/100")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                linearProgress(pct: stressIndex, color: Color(UIColor.systemBlue))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右侧：高优待办数量与占比
            VStack(alignment: .leading, spacing: 8) {
                Text("高优待办")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text("\(highPriorityCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(Color(UIColor.systemGreen))
                    Text(String(format: "%.1f%%", highPriorityRatio * 100))
                        .font(.caption)
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding(16)
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(DesignToken.cornerRadius)
    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
}

private func linearProgress(pct: Double, color: Color) -> some View {
    GeometryReader { geo in
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(UIColor.systemGray5))
                .frame(height: 8)
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: max(0, geo.size.width * CGFloat(pct)), height: 8)
        }
    }
    .frame(height: 8)
}
    
    private func legendDot(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
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
                    TextEditor(text: $newImprovement.improvementDescription)
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
                            newImprovement = Improvement(emoji: "📝", name: "", improvementDescription: "", priority: .medium)
                        }
                    }
                    .disabled(newImprovement.name.isEmpty)
                }
            }
        }
    }

    // 删除待改进项
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
    var improvementDescription: String
    var priority: Priority

    init(id: UUID = UUID(), emoji: String, name: String, improvementDescription: String, priority: Priority) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.improvementDescription = improvementDescription
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