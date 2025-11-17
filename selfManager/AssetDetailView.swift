//
//  AssetDetailView.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import SwiftUI
import SwiftData

struct AssetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 使用 SwiftData 查询资产数据
    @Query(sort: \Asset.lastUpdateDate, order: .reverse) private var assets: [Asset]
    
    // 当前资产对象
    private var asset: Asset {
        if let firstAsset = assets.first {
            return firstAsset
        } else {
            let newAsset = Asset()
            modelContext.insert(newAsset)
            return newAsset
        }
    }
    
    // 编辑状态
    @State private var isEditing: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var selectedTab: Int = 0 // 添加标签页切换状态
    
    // 临时编辑值
    @State private var tempCash: String = ""
    @State private var tempDebt: String = ""
    @State private var tempOther: String = ""
    
    // 资产历史数据（模拟数据，实际应用中应从数据库获取）
    private var assetHistory: [(date: String, amount: Double, change: String)] = [
        ("2024年5月", 13.8, "+2.3"),
        ("2024年4月", 11.5, "+1.5"),
        ("2024年3月", 10.0, "-2.0"),
        ("2024年2月", 12.0, "+3.0"),
        ("2024年1月", 9.0, "+0.5")
    ]
    
    var totalAssets: Double {
        asset.totalAssets
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 总资产概览卡片 - 始终显示在顶部
                totalAssetCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // 标签页切换
                tabView
                    .padding(.top, 16)
                
                // 根据选中的标签页显示不同内容
                TabView(selection: $selectedTab) {
                    // 资产详情标签页
                    ScrollView {
                        VStack(spacing: 20) {
                            // 资产分类详情
                            assetBreakdownCard
                            
                            // 资产配置饼图
                            assetAllocationChart
                            
                            // 底部说明
                            assetGuidanceCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .tag(0)
                    
                    // 资产趋势标签页
                    ScrollView {
                        VStack(spacing: 20) {
                            // 资产趋势图表
                            assetTrendCard
                            
                            // 资产记录历史
                            assetHistoryCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .tag(1)
                    
                    // 资产管理标签页
                    ScrollView {
                        VStack(spacing: 20) {
                            // 资产管理选项
                            assetManagementOptionsCard
                            
                            // 资产目标设置
                            assetGoalSettingsCard
                            
                            // 资产管理小贴士
                            assetGuidanceCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("我的资产")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("back".localized)
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "编辑") {
                        if isEditing {
                            saveAssets()
                        } else {
                            startEditing()
                        }
                    }
                }
            }
            .alert("资产已更新", isPresented: $showingSaveAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("您的资产信息已成功保存")
            }
            .toolbar(.hidden, for: .tabBar)
        }
    }
    
    // 标签页切换视图
    private var tabView: some View {
        HStack(spacing: 0) {
            ForEach([
                ("资产详情", "chart.pie.fill"),
                ("资产趋势", "chart.line.uptrend.xyaxis"),
                ("资产管理", "gearshape.fill")
            ], id: \.0) { title, icon in
                Button(action: {
                    withAnimation {
                        selectedTab = ["资产详情", "资产趋势", "资产管理"].firstIndex(of: title) ?? 0
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                        Text(title)
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(selectedTab == ["资产详情", "资产趋势", "资产管理"].firstIndex(of: title) ? Color(UIColor.systemBlue) : Color(UIColor.secondaryLabel))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
    
    // 总资产概览卡片 - 现代化设计
    private var totalAssetCard: some View {
        VStack(spacing: 16) {
            // 顶部信息栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总资产")
                        .font(.headline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text(formatDate(asset.lastUpdateDate))
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                Spacer()
                
                // 月度变化指示器
                HStack(spacing: 4) {
                    Image(systemName: totalAssets >= asset.totalAssets - 1.0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(totalAssets >= asset.totalAssets - 1.0 ? Color(UIColor.systemGreen) : Color(UIColor.systemRed))
                    
                    Text(totalAssets >= asset.totalAssets - 1.0 ? "+2.3%" : "-1.5%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(totalAssets >= asset.totalAssets - 1.0 ? Color(UIColor.systemGreen) : Color(UIColor.systemRed))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(totalAssets >= asset.totalAssets - 1.0 ? Color(UIColor.systemGreen).opacity(0.1) : Color(UIColor.systemRed).opacity(0.1))
                .cornerRadius(12)
            }
            
            // 总资产数值 - 大号显示
            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", totalAssets))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(totalAssets >= 0 ? Color(UIColor.systemBlue) : Color(UIColor.systemRed))
                
                Text("万元")
                    .font(.title2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .padding(.bottom, 8)
            }
            
            // 资产分布指示条
            VStack(spacing: 8) {
                // 进度条
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // 现金部分
                        Rectangle()
                            .fill(Color(UIColor.systemGreen))
                            .frame(width: geometry.size.width * CGFloat(asset.cashAmount / (asset.cashAmount + asset.otherAmount + asset.debtAmount)))
                        
                        // 其他资产部分
                        Rectangle()
                            .fill(Color(UIColor.systemBlue))
                            .frame(width: geometry.size.width * CGFloat(asset.otherAmount / (asset.cashAmount + asset.otherAmount + asset.debtAmount)))
                        
                        // 负债部分
                        Rectangle()
                            .fill(Color(UIColor.systemRed))
                            .frame(width: geometry.size.width * CGFloat(asset.debtAmount / (asset.cashAmount + asset.otherAmount + asset.debtAmount)))
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                // 图例
                HStack {
                    // 现金图例
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(UIColor.systemGreen))
                            .frame(width: 8, height: 8)
                        Text("现金")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    // 其他资产图例
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(UIColor.systemBlue))
                            .frame(width: 8, height: 8)
                        Text("其他资产")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    // 负债图例
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(UIColor.systemRed))
                            .frame(width: 8, height: 8)
                        Text("负债")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产分类详情卡片 - 现代化设计
    private var assetBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text("资产详情")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !isEditing {
                    Button(action: { startEditing() }) {
                        Label("编辑", systemImage: "pencil")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            VStack(spacing: 16) {
                // 现金资产
                assetRow(
                    icon: "banknote",
                    title: "现金资产",
                    amount: asset.cashAmount,
                    color: Color(UIColor.systemGreen),
                    isEditing: isEditing,
                    editValue: $tempCash,
                    description: "活期存款、定期存款等"
                )
                
                Divider()
                
                // 其他资产
                assetRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "其他资产",
                    amount: asset.otherAmount,
                    color: Color(UIColor.systemBlue),
                    isEditing: isEditing,
                    editValue: $tempOther,
                    description: "股票、基金、房产等"
                )
                
                Divider()
                
                // 负债
                assetRow(
                    icon: "creditcard",
                    title: "负债",
                    amount: asset.debtAmount,
                    color: Color(UIColor.systemRed),
                    isEditing: isEditing,
                    editValue: $tempDebt,
                    description: "信用卡、贷款等"
                )
            }
            
            // 保存按钮 - 仅在编辑模式下显示
            if isEditing {
                Button(action: { saveAssets() }) {
                    Text("保存更改")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.systemBlue))
                        .cornerRadius(10)
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产配置饼图
    private var assetAllocationChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("资产配置")
                .font(.headline)
                .fontWeight(.bold)
            
            // 饼图区域
            ZStack {
                // 饼图（简化版，实际应用中可使用第三方图表库如SwiftUICharts）
                Circle()
                    .trim(from: 0, to: CGFloat(asset.cashAmount / (asset.cashAmount + asset.otherAmount)))
                    .stroke(Color(UIColor.systemGreen), lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: CGFloat(asset.cashAmount / (asset.cashAmount + asset.otherAmount)), to: 1)
                    .stroke(Color(UIColor.systemBlue), lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                
                // 中心文本
                VStack(spacing: 4) {
                    Text("净资产")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text(String(format: "%.1f万", totalAssets))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            
            // 图例
            VStack(spacing: 12) {
                // 现金资产图例
                HStack {
                    Circle()
                        .fill(Color(UIColor.systemGreen))
                        .frame(width: 12, height: 12)
                    
                    Text("现金资产")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f万", asset.cashAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(String(format: "%.0f%%", asset.cashAmount / (asset.cashAmount + asset.otherAmount) * 100))
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .frame(width: 40, alignment: .trailing)
                }
                
                // 其他资产图例
                HStack {
                    Circle()
                        .fill(Color(UIColor.systemBlue))
                        .frame(width: 12, height: 12)
                    
                    Text("其他资产")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f万", asset.otherAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(String(format: "%.0f%%", asset.otherAmount / (asset.cashAmount + asset.otherAmount) * 100))
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .frame(width: 40, alignment: .trailing)
                }
                
                Divider()
                
                // 负债图例
                HStack {
                    Circle()
                        .fill(Color(UIColor.systemRed))
                        .frame(width: 12, height: 12)
                    
                    Text("负债")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f万", asset.debtAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(String(format: "%.0f%%", asset.debtAmount / totalAssets * 100))
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产趋势卡片 - 更新为实际功能
    private var assetTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("资产趋势")
                .font(.headline)
                .fontWeight(.bold)
            
            // 趋势图表区域
            VStack(spacing: 20) {
                // 时间选择器
                Picker("时间范围", selection: .constant(0)) {
                    Text("近3个月").tag(0)
                    Text("近6个月").tag(1)
                    Text("近1年").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)
                
                // 趋势图（简化版，实际应用中可使用第三方图表库）
                ZStack(alignment: .bottom) {
                    // 背景网格
                    VStack(spacing: 0) {
                        ForEach(0..<4) { _ in
                            Divider()
                                .opacity(0.5)
                            Spacer()
                        }
                    }
                    
                    // 折线图
                    HStack(alignment: .bottom, spacing: (UIScreen.main.bounds.width - 80) / CGFloat(assetHistory.count - 1)) {
                        ForEach(assetHistory.indices, id: \.self) { index in
                            VStack(spacing: 4) {
                                // 数据点
                                Circle()
                                    .fill(Color(UIColor.systemBlue))
                                    .frame(width: 8, height: 8)
                                    .background(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 12, height: 12)
                                    )
                                    .offset(y: -4)
                                
                                // 数据柱
                                Rectangle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.3))
                                    .frame(width: 4, height: CGFloat(Double(assetHistory[index].amount)) * 10)
                                
                                // 月份标签
                                Text(assetHistory[index].date)
                                    .font(.caption2)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .rotationEffect(.degrees(-45))
                                    .offset(y: 10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 200)
                .padding(.top, 20)
                
                // 数据统计
                HStack(spacing: 20) {
                    // 月均增长
                    VStack(alignment: .leading, spacing: 4) {
                        Text("月均增长")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("+0.5万")
                                .font(.headline)
                                .foregroundColor(Color(UIColor.systemGreen))
                            
                            Text("+5.2%")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.systemGreen))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 年度目标
                    VStack(alignment: .leading, spacing: 4) {
                        Text("年度目标")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("12.0/20.0万")
                                .font(.headline)
                            
                            Text("60%")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 16)
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
    
    // 资产管理选项卡片
    private var assetManagementOptionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("资产管理")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // 添加资产类别
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(UIColor.systemBlue))
                        
                        Text("添加资产类别")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 设置资产目标
                Button(action: {}) {
                    HStack {
                        Image(systemName: "target")
                            .font(.title3)
                            .foregroundColor(Color(UIColor.systemGreen))
                        
                        Text("设置资产目标")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 导出资产报告
                Button(action: {}) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(Color(UIColor.systemOrange))
                        
                        Text("导出资产报告")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 资产目标设置卡片
    private var assetGoalSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("资产目标")
                .font(.headline)
                .fontWeight(.bold)
            
            // 年度目标进度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("2024年度目标")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("12.0/20.0万")
                        .font(.subheadline)
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        // 进度
                        Rectangle()
                            .fill(Color(UIColor.systemBlue))
                            .frame(width: geometry.size.width * 0.6, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                // 进度说明
                HStack {
                    Text("已完成60%")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Spacer()
                    
                    Text("距离年底还有\(daysUntilEndOfYear())天")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // 月度增长目标
            VStack(alignment: .leading, spacing: 12) {
                Text("月度增长目标")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Text("+0.5万/月")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("目标")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Text("+0.8万/月")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("调整")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.systemBlue))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 计算距离年底的天数
    private func daysUntilEndOfYear() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        return calendar.dateComponents([.day], from: today, to: endOfYear).day ?? 0
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
                Text("• 设置合理的资产增长目标")
                Text("• 控制负债比例在总资产的30%以内")
            }
            .font(.subheadline)
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // 资产行组件
    private func assetRow(icon: String, title: String, amount: Double, color: Color, isEditing: Bool, editValue: Binding<String>, description: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                // 图标
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
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
            
            // 描述文本
            if !isEditing {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
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
        tempCash = String(format: "%.1f", asset.cashAmount)
        tempDebt = String(format: "%.1f", asset.debtAmount)
        tempOther = String(format: "%.1f", asset.otherAmount)
        isEditing = true
    }
    
    // 保存资产
    private func saveAssets() {
        // 验证并保存数据
        if let cash = Double(tempCash), let debt = Double(tempDebt), let other = Double(tempOther) {
            // 更新资产模型
            asset.cashAmount = cash
            asset.debtAmount = debt
            asset.otherAmount = other
            asset.lastUpdateDate = Date()
            
            // 保存到数据库
            try? modelContext.save()
            
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