//
//  HomeView.swift
//  selfManager
//
//  Created by Zack on 2024/12/31.
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
    @State private var showingSettings = false
    
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
    @Query(sort: \Asset.lastUpdateDate, order: .reverse) private var assets: [Asset]
    
    private var asset: Asset {
        if let firstAsset = assets.first {
            return firstAsset
        } else {
            let newAsset = Asset()
            modelContext.insert(newAsset)
            return newAsset
        }
    }
    
    // 心情数据
    private let moods = ["😊", "😢", "😡", "😴", "🤔", "😎"]
    
    // 成就数据
    private let achievements = ["🏆", "🥇", "🥈", "🥉", "🎖️"]
    private let achievementLabels = ["早起达人", "阅读先锋", "运动健将", "社交达人", "工作能手"]
    
    // 弱点数据
    private let weakPoints = ["🍔", "🛌", "📱"]
    
    // 待改进数据
    private let improvements = ["📱", "🍔", "🛌", "🎮", "💤"]
    
    // 待改进标签
    private let improvementLabels = ["手机使用", "饮食习惯", "作息时间", "游戏时间", "午休习惯"]
    
    // 焦虑数据
    private let anxieties = ["工作压力大", "睡眠不足", "缺乏锻炼"]
    
    // 初始化方法
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部空间占位，与顶部标题栏高度相同
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40) // 将高度从 140 减小到 80
                        
                        // 用户个人信息卡片
                        userProfileSection
                            .sheet(isPresented: $showingEdit) {
                                UserEditView(user: user)
                            }
                        
                        // 资产信息卡片
                        assetSection
                        
                        // 积极的标签
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
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        
                        // 目标区域
                        goalSection
                        
                        // 心情和成就区域
                        HStack(spacing: 16) {
                            // 心情区域
                            moodSection
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 成就区域
                            achievementSection
                                .frame(maxWidth: .infinity)
                        }
                        
                        // 需要改进的标签
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
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        
                        // 待改进区域
                        improvementSection
                        
                        // 焦虑区域
                        anxietySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
                .background(Color(UIColor.systemGroupedBackground))
                .coordinateSpace(name: "scroll")
                
                // 悬浮的顶部标题栏
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("个人概览")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.label))
                        }
                        
                        Spacer()
                        
                        // 设置按钮
                        Button(action: {
                            showingSettings = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemGray4).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(UIColor.systemGray))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 8)
                        
                        // 通知按钮
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, 44) // 使用固定值代替弃用的API
                }
                .frame(maxWidth: .infinity)
                .background(BlurView(style: .systemMaterial))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                .ignoresSafeArea(.all, edges: .top)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // 模糊背景视图
    // BlurView结构体 - 用于创建模糊效果背景
    struct BlurView: UIViewRepresentable {
        var style: UIBlurEffect.Style
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: style)
        }
    }
    
    // 用户信息卡片
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 头像
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
                    // 用户名
                    Text(user.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                    // 标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .foregroundColor(Color(UIColor.systemBlue))
                                    // 可以添加图标
                                }
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(UIColor.systemBlue).opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Spacer()
                
                // 详情按钮（替换铅笔按钮为右上角箭头）
                Button(action: { showingEdit = true }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            // 用户描述
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
    
    // 资产信息卡片
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
                // 左侧标题
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemGreen))
                    Text("资产概览")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 右侧总资产
                HStack(spacing: 2) {
                    Text(String(format: "%.1f", asset.totalAssets))
                        .fontWeight(.heavy)
                        .foregroundColor(Color(UIColor.systemBlue))
                    Text("W")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            
            // 资产详情
            HStack(spacing: 20) {
                // 现金
                VStack(alignment: .leading, spacing: 4) {
                    Text("现金")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.cashAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // 其他资产
                VStack(alignment: .leading, spacing: 4) {
                    Text("其他")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.otherAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // 负债
                VStack(alignment: .leading, spacing: 4) {
                    Text("负债")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(String(format: "%.1f", asset.debtAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemRed))
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.systemGray5).opacity(0.5), lineWidth: 0.5)
                )
        )
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 目标区域
    @State private var showingGoalPopup = false
    @State private var goalFilterExpanded = true
    @State private var selectedGoalType: GoalType? = nil
    @State private var selectedImportance: GoalImportance? = nil
    @State private var savedFilteredGoals: [Goal] = []
    
    private var goalSection: some View {
        Button(action: {
            // 显示目标弹窗
            showingGoalPopup = true
        }) {
            goalCardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingGoalPopup) {
            GoalPopupView(
                goalFilterExpanded: $goalFilterExpanded,
                selectedGoalType: $selectedGoalType,
                selectedImportance: $selectedImportance,
                savedFilteredGoals: $savedFilteredGoals
            )
        }
    }
    
    private var goalCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemBlue))
                Text("近期目标")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                
                // 目标数量
                HStack(spacing: 4) {
                    Text("\(goals.count)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemBlue))
                    Text("个目标")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                // 筛选按钮
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(6)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .clipShape(Circle())
            }
            
            // 确定要显示的目标列表：如果有保存的筛选结果则显示筛选结果，否则显示所有目标
            let goalsToDisplay = !savedFilteredGoals.isEmpty ? savedFilteredGoals : goals
            
            if goalsToDisplay.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Text("暂无目标")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Button(action: {
                        // 跳转到目标页面
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
            } else {
                // 目标列表 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(goalsToDisplay.prefix(3)) { goal in
                            VStack(alignment: .leading, spacing: 10) {
                                // 目标名称和优先级
                                HStack {
                                    Image(systemName: goal.goalImportance.iconName)
                                        .foregroundColor(goal.goalImportance.color)
                                        .font(.system(size: 14))
                                    
                                    Text(goal.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .lineLimit(1)
                                        .foregroundColor(Color(UIColor.label))
                                }
                                
                                // 进度条
                                VStack(alignment: .leading, spacing: 6) {
                                    ProgressView(value: goal.progress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor.systemBlue)))
                                        .scaleEffect(y: 1.2)
                                    
                                    HStack {
                                        Text("\(Int(goal.progress * 100))%")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(UIColor.systemBlue))
                                        
                                        Spacer()
                                        
                                        // 目标类型标签
                                        Text(goal.goalType.rawValue)
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(UIColor.systemGray))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(UIColor.systemGray6))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .frame(width: 150, height: 80)
                            .padding(16)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                        }
                        
                        // 查看更多按钮
                        if goalsToDisplay.count > 3 {
                            Button(action: {
                                showingGoalPopup = true
                            }) {
                                VStack(spacing: 10) {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(UIColor.systemBlue))
                                    
                                    Text("查看更多")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(UIColor.systemBlue))
                                }
                                .frame(width: 100, height: 80)
                                .padding(16)
                                .background(Color(UIColor.systemBlue).opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
                .frame(height: 140) // 增加高度以适应卡片
            }
            
            // 底部提示文本
            HStack {
                Spacer()
                if !savedFilteredGoals.isEmpty {
                    // 显示筛选状态
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 10))
                        Text("已筛选 · 点击修改")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(UIColor.systemBlue))
                } else {
                    Text("点击查看全部目标并筛选")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // 心情区域 - 扁平化设计
    private var moodSection: some View {
        Button(action: {
            // 这里可以添加心情详情页面的跳转
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemYellow))
                    Text("心情")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                // 心情图标 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<moods.count, id: \.self) { index in
                            Image(systemName: getMoodIcon(for: index))
                                .font(.system(size: 24))
                                .foregroundColor(getMoodColor(for: index))
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
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 成就展示区域 - 扁平化设计
    private var achievementSection: some View {
        Button(action: {
            showingAchievementDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemYellow))
                    Text("成就")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                // 成就图标 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<achievements.count, id: \.self) { index in
                            VStack(spacing: 4) {
                                Image(systemName: getAchievementIcon(for: index))
                                    .font(.title2)
                                    .foregroundColor(Color(UIColor.systemYellow))
                                    .frame(width: 42, height: 42)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(8)
                                
                                // 添加简短标签
                                Text(achievementLabels[index])
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
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAchievementDetail) {
            AchievementDetailView()
        }
    }
    
    private var achievementCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemYellow))
                Text("成就")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                
                // 详情按钮（替换铅笔按钮为右上角箭头）
                Button(action: { showingAchievementDetail = true }) {
                    Image(systemName: "chevron.right")
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
    private var improvementSection: some View {
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
            HStack(spacing: 8) {
                Image(systemName: "pencil.and.outline")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemOrange))
                Text("待改进")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
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
    
    // 焦虑区域 - 扁平化设计
    private var anxietySection: some View {
        Button(action: {
            // 这里可以添加焦虑详情页面的跳转
        }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(Color(UIColor.systemRed))
                    Text("最近焦虑")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    
                    // 详情按钮
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                // 焦虑列表
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(anxieties, id: \.self) { anxiety in
                        HStack(spacing: 12) {
                            // 警告图标
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
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 获取成就图标的辅助函数
    func getAchievementIcon(for index: Int) -> String {
        let achievementIcons = ["sunrise.fill", "book.fill", "figure.run", "person.2.fill", "briefcase.fill"]
        return index < achievementIcons.count ? achievementIcons[index] : "star.fill"
    }
    
    // 获取心情图标的辅助函数
    func getMoodIcon(for index: Int) -> String {
        let moodIcons = ["face.smiling"]
        return index < moodIcons.count ? moodIcons[index] : "face.dashed"
    }
    
    // 获取心情颜色的辅助函数
    func getMoodColor(for index: Int) -> Color {
        let moodColors = [
            Color(UIColor.systemYellow),  // 开心
            Color(UIColor.systemBlue),    // 悲伤
            Color(UIColor.systemRed),     // 愤怒
            Color(UIColor.systemGray),    // 疲倦
            Color(UIColor.systemPurple),  // 思考
            Color(UIColor.systemOrange)   // 酷
        ]
        return index < moodColors.count ? moodColors[index] : Color(UIColor.systemGray)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .modelContainer(for: Item.self, inMemory: true)
    }
}
