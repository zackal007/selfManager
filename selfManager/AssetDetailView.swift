//
//  AssetDetailView.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import SwiftUI
import SwiftData

struct AssetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 资产数据 - 这里可以后续改为从数据库读取
    @State private var cashAmount: Double = 10.0
    @State private var debtAmount: Double = 5.0
    @State private var otherAmount: Double = 8.0
    @State private var lastUpdateDate: Date = Date()
    
    // 编辑状态
    @State private var isEditing: Bool = false
    @State private var showingSaveAlert: Bool = false
    
    // 临时编辑值
    @State private var tempCash: String = ""
    @State private var tempDebt: String = ""
    @State private var tempOther: String = ""
    
    var totalAssets: Double {
        cashAmount + otherAmount - debtAmount
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 总资产概览卡片
                    totalAssetCard
                    
                    // 资产分类详情
                    assetBreakdownCard
                    
                    // 资产趋势图表区域（占位）
                    assetTrendCard
                    
                    // 资产记录历史
                    assetHistoryCard
                    
                    // 底部说明
                    assetGuidanceCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("资产管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "编辑") {
                        if isEditing {
                            saveAssets()
                        } else {
                            startEditing()
                        }
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                }
            }
        }
        .alert("资产已更新", isPresented: $showingSaveAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("您的资产信息已成功保存")
        }
    }
    
    // 总资产概览卡片
    private var totalAssetCard: some View {
        VStack(spacing: 16) {
            // 总资产数值
            VStack(spacing: 8) {
                Text("总资产")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(String(format: "%.1f", totalAssets))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(totalAssets >= 0 ? Color(UIColor.systemGreen) : Color(UIColor.systemRed))
                    
                    Text("万元")
                        .font(.title2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.bottom, 8)
                }
            }
            
            // 上次更新时间
            Text("上次更新：\(formatDate(lastUpdateDate))")
                .font(.caption)
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产分类详情卡片
    private var assetBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("资产详情")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // 现金资产
                assetRow(
                    icon: "💰",
                    title: "现金资产",
                    amount: cashAmount,
                    color: Color(UIColor.systemGreen),
                    isEditing: isEditing,
                    editValue: $tempCash
                )
                
                Divider()
                
                // 其他资产
                assetRow(
                    icon: "📈",
                    title: "其他资产",
                    amount: otherAmount,
                    color: Color(UIColor.systemBlue),
                    isEditing: isEditing,
                    editValue: $tempOther
                )
                
                Divider()
                
                // 负债
                assetRow(
                    icon: "💳",
                    title: "负债",
                    amount: debtAmount,
                    color: Color(UIColor.systemRed),
                    isEditing: isEditing,
                    editValue: $tempDebt
                )
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产趋势卡片（占位）
    private var assetTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("资产趋势")
                .font(.headline)
                .fontWeight(.bold)
            
            // 简单的趋势展示
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月变化")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(Color(UIColor.systemGreen))
                            .font(.caption)
                        Text("+2.3万")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }
                
                Spacer()
                
                // 占位图表区域
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 120, height: 60)
                    .overlay(
                        Text("📊")
                            .font(.title2)
                    )
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产记录历史卡片
    private var assetHistoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("记录历史")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("查看全部") {
                    // 查看全部历史记录
                }
                .font(.caption)
                .foregroundColor(Color(UIColor.systemBlue))
            }
            
            VStack(spacing: 12) {
                // 历史记录项（示例）
                historyRow(date: "2024年1月", totalAsset: 11.5, change: "+1.5")
                historyRow(date: "2023年12月", totalAsset: 10.0, change: "-2.0")
                historyRow(date: "2023年11月", totalAsset: 12.0, change: "+3.0")
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产管理指导卡片
    private var assetGuidanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 资产管理小贴士")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• 建议每月更新一次资产状况")
                Text("• 关注资产配置的合理性")
                Text("• 定期评估投资收益和风险")
                Text("• 保持适当的现金储备")
            }
            .font(.subheadline)
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // 资产行组件
    private func assetRow(icon: String, title: String, amount: Double, color: Color, isEditing: Bool, editValue: Binding<String>) -> some View {
        HStack {
            // 图标
            Text(icon)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            // 标题
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            // 金额
            if isEditing {
                HStack(spacing: 4) {
                    TextField("0.0", text: editValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .keyboardType(.decimalPad)
                    Text("万")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            } else {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    Text("万")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
        }
    }
    
    // 历史记录行
    private func historyRow(date: String, totalAsset: Double, change: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("总资产 \(String(format: "%.1f", totalAsset))万")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Spacer()
            
            Text(change)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(change.hasPrefix("+") ? Color(UIColor.systemGreen) : Color(UIColor.systemRed))
        }
        .padding(.vertical, 4)
    }
    
    // 开始编辑
    private func startEditing() {
        tempCash = String(format: "%.1f", cashAmount)
        tempDebt = String(format: "%.1f", debtAmount)
        tempOther = String(format: "%.1f", otherAmount)
        isEditing = true
    }
    
    // 保存资产
    private func saveAssets() {
        // 验证并保存数据
        if let cash = Double(tempCash), let debt = Double(tempDebt), let other = Double(tempOther) {
            cashAmount = cash
            debtAmount = debt
            otherAmount = other
            lastUpdateDate = Date()
            
            // 这里可以添加保存到数据库的逻辑
            
            isEditing = false
            showingSaveAlert = true
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

#Preview {
    AssetDetailView()
}