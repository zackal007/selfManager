//
//  ContentView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Query(sort: \Goal.createTime, order: .reverse) private var goals: [Goal]
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    @State private var showingEdit = false
    @State private var showingAssetDetail = false
    @State private var showingImprovementDetail = false
    @State private var showingAchievementDetail = false
    
    // 用户信息
    @Query private var users: [User]

    private var user: User {
        if let firstUser = users.first {
            return firstUser
        } else {
            let newUser = User()
            modelContext.insert(newUser)
            return newUser
        }
    }
    
    // 资产信息
    @Query private var assets: [Asset]
    
    private var asset: Asset {
        if let firstAsset = assets.first {
            return firstAsset
        } else {
            let newAsset = Asset()
            modelContext.insert(newAsset)
            return newAsset
        }
    }
    
    // 心情记录
    private let moods = ["😊", "😢", "😡", "😴", "🤔", "😎"]
    
    // 成就图标
    private let achievements = ["🏆", "🥇", "🥈", "🥉", "🎖️"]
    private let achievementLabels = ["早起达人", "阅读先锋", "运动健将", "社交达人", "工作能手"]
    
    // 缺点/待改进项
    private let weakPoints = ["🍔", "🛌", "📱"]
    
    // 待改进项
    private let improvements = ["📱", "🍔", "🛌", "🎮", "💤"]
    
    // 待改进项标签
    private let improvementLabels = ["手机使用", "饮食习惯", "作息时间", "游戏时间", "午休习惯"]
    
    // 最近焦虑
    private let anxieties = ["工作压力大", "睡眠不足", "缺乏锻炼"]
    
    // 初始化方法，接收selectedTab绑定
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                VStack(spacing: 20) {
                    // 顶部标题 - 优化设计
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("个人概览")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.label))
                            
                            Text("今天也要加油哦 💪")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                        
                        Spacer()
                        
                        // 通知按钮 - 优化设计
                        Button(action: {}) {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "bell.badge")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // 用户信息卡片
                userProfileSection
                    .sheet(isPresented: $showingEdit) {
                        UserEditView(user: user)
                    }
                
                // 资产信息
                assetSection
                
                // 积极的模块标题 - 优化设计
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(UIColor.systemGreen).opacity(0.2))
                            .frame(width: 6, height: 6)
                        
                        Text("积极的")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                
                // 目标信息 - 独立卡片
                goalSection
                    .padding(18)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
                
                // 心情记录和成就展示 - 放在同一行
                HStack(spacing: 16) {
                    // 心情记录 - 独立卡片
                    moodSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 成就展示 - 独立卡片
                    achievementSection
                        .frame(maxWidth: .infinity)
                }
                
                // 需要改进的模块标题 - 优化设计
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(UIColor.systemOrange).opacity(0.2))
                            .frame(width: 6, height: 6)
                        
                        Text("需要改进的")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemOrange))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                
                // 待改进 - 独立卡片
                improvementSection
                
                // 最近焦虑 - 独立卡片
                anxietySection
                    .padding(18)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
                }
                .padding(.top, 50) // 为顶部模糊效果留出空间
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.bottom)
            
            // 顶部模糊效果
            VisualEffectBlur(blurStyle: .systemMaterial)
                .frame(height: 50)
                .edgesIgnoringSafeArea(.top)
        }
    }
    
    // 用户信息区域 - 现代化精致设计
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 用户头像 - 现代化设计
                Text(user.avatar)
                    .font(.system(size: 52))
                    .frame(width: 68, height: 68)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(UIColor.systemBlue).opacity(0.1), Color(UIColor.systemBlue).opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(UIColor.systemBlue).opacity(0.3), Color(UIColor.systemBlue).opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(UIColor.systemBlue).opacity(0.15), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    // 用户名 - 精致字体
                    Text(user.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                    
                    // 标签 - 现代化样式
                    HStack(spacing: 8) {
                        ForEach(user.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(UIColor.systemBlue).opacity(0.12))
                                )
                                .foregroundColor(Color(UIColor.systemBlue))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(UIColor.systemBlue).opacity(0.2), lineWidth: 0.5)
                                )
                        }
                    }
                }
                
                Spacer()
                
                // 编辑按钮 - 现代化设计
                Button(action: { showingEdit = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 36, height: 36)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.systemBlue).opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
            
            // 用户描述 - 精致排版
            Text(user.userDescription)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineSpacing(2)
                .lineLimit(3)
                .padding(.top, 2)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.systemGray5).opacity(0.5), lineWidth: 0.5)
                )
        )
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 资产区域 - 健康风格设计
    private var assetSection: some View {
        Button(action: {
            showingAssetDetail = true
        }) {
            assetCardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAssetDetail) {
            AssetDetailView()
        }
    }
    
    private var assetCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                    // 标题和emoji图标
                    HStack(spacing: 6) {
                        Text("💰")
                            .font(.title3)
                        Text("资产概览")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor.label))
                    }
                    
                    Spacer()
                    
                    // 总资产
                    HStack(spacing: 2) {
                        Text(String(format: "%.1f", asset.totalAssets))
                            .fontWeight(.heavy)
                            .foregroundColor(Color(UIColor.systemBlue))
                        Text("W")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    .font(.subheadline)
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            
            // 资产数据
            HStack(spacing: 0) {
                // 现金
                VStack(spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("现金")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    Text(String(format: "%.1f", asset.cashAmount) + "W")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 1, height: 36)
                
                // 负债
                VStack(spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("负债")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    Text(String(format: "%.1f", asset.debtAmount) + "W")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 1, height: 36)
                
                // 其他
                VStack(spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("其他")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    Text(String(format: "%.1f", asset.otherAmount) + "W")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
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
    
    // 目标区域 - 优化设计
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 8) {
                    Text("🎯")
                        .font(.system(size: 20))
                    Text("近期目标")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 目标总数 - 可点击切换到目标标签页
                Button(action: {
                    // 切换到目标标签页（索引为1）
                    selectedTab = 1
                }) {
                    HStack(spacing: 4) {
                        Text("\(goals.count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemBlue))
                        Text("个目标")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 详情按钮 - 可点击切换到目标标签页
                Button(action: {
                    // 切换到目标标签页（索引为1）
                    selectedTab = 1
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            if goals.isEmpty {
                // 空状态 - 优化设计
                VStack(spacing: 12) {
                    Text("暂无目标")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Button(action: {
                        // 切换到目标标签页（索引为1）
                        selectedTab = 1
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("添加目标")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
            } else {
                // 目标列表 - 水平滚动优化
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(goals.prefix(5)) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                VStack(alignment: .leading, spacing: 10) {
                                    // 目标名称
                                    Text(goal.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(Color(UIColor.label))
                                    
                                    // 进度条优化
                                    VStack(alignment: .leading, spacing: 6) {
                                        ProgressView(value: goal.progress, total: 1.0)
                                            .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor.systemBlue)))
                                            .scaleEffect(y: 1.2)
                                        
                                        HStack {
                                            Text("\(Int(goal.progress * 100))%")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color(UIColor.systemBlue))
                                            Spacer()
                                            if goal.progress >= 1.0 {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(UIColor.systemGreen))
                                            }
                                        }
                                    }
                                }
                                .frame(width: 150, height: 80)
                                .padding(16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // 心情区域 - 优化设计
    var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 8) {
                    Text("😊")
                        .font(.system(size: 20))
                    Text("心情")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            // 心情图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moods, id: \.self) { mood in
                        Text(mood)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            .frame(height: 56)
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // 成就展示区域 - 扁平化设计
    var achievementSection: some View {
        Button(action: {
            showingAchievementDetail = true
        }) {
            achievementCardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAchievementDetail) {
            AchievementDetailView()
        }
    }
    
    private var achievementCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🏆")
                        .font(.title3)
                    Text("成就")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            // 成就图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(achievements, id: \.self) { achievement in
                        VStack(spacing: 4) {
                            Text(achievement)
                                .font(.title2)
                                .frame(width: 42, height: 42)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                            
                            // 添加简短标签
                            Text(achievementLabels[achievements.firstIndex(of: achievement) ?? 0])
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .lineLimit(1)
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(height: 80) // 增加高度以适应标签
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 待改进区域 - 扁平化设计
    var improvementSection: some View {
        Button(action: {
            showingImprovementDetail = true
        }) {
            improvementCardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingImprovementDetail) {
            ImprovementDetailView()
        }
    }
    
    private var improvementCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("📝")
                        .font(.title3)
                    Text("待改进")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            // 待改进图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(improvements, id: \.self) { improvement in
                        VStack(spacing: 4) {
                            Text(improvement)
                                .font(.title2)
                                .frame(width: 42, height: 42)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                            
                            // 添加简短标签
                            Text(improvementLabels[improvements.firstIndex(of: improvement) ?? 0])
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .lineLimit(1)
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(height: 80) // 增加高度以适应标签
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 最近焦虑区域 - 优化设计
    var anxietySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 8) {
                    Text("😰")
                        .font(.system(size: 20))
                    Text("最近焦虑")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            // 焦虑列表
            VStack(alignment: .leading, spacing: 10) {
                ForEach(anxieties, id: \.self) { anxiety in
                    HStack(spacing: 12) {
                        // 焦虑图标
                        Text("⚠️")
                            .font(.system(size: 16))
                        
                        // 焦虑内容
                        Text(anxiety)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .modelContainer(for: Item.self, inMemory: true)
    }
}

// 模糊效果视图
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
