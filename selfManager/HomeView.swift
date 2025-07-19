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
    
    // 用户信息
    private let userInfo = "张三"
    
    // 资产信息
    private let assets = (现金: 10, 负债: 5, 其他: 8)
    
    // 心情记录
    private let moods = ["😊", "😢", "😡", "😴", "🤔", "😎"]
    
    // 成就图标
    private let achievements = ["🏆", "🥇", "🥈", "🥉", "🎖️"]
    
    // 缺点/待改进项
    private let weakPoints = ["🍔", "🛌", "📱"]
    
    // 待改进项
    private let improvements = ["📱", "🍔", "🛌", "🎮", "💤"]
    
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
                VStack(spacing: 16) {
                    // 顶部标题
                    HStack {
                        Text("个人概览")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "bell.badge")
                                .font(.title2)
                                .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 用户信息卡片
                userProfileSection
                
                // 资产信息
                assetSection
                
                // 积极的模块标题
                HStack {
                    Text("积极的")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 4)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                
                // 目标信息 - 独立卡片
                goalSection
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                
                // 心情记录和成就展示 - 放在同一行
                HStack(spacing: 12) {
                    // 心情记录 - 独立卡片
                    moodSection
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 成就展示 - 独立卡片
                    achievementSection
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                }
                
                // 需要改进的模块标题
                HStack {
                    Text("需要改进的")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 4)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                
                // 待改进 - 独立卡片
                improvementSection
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                
                // 最近焦虑 - 独立卡片
                anxietySection
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
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
    
    // 用户信息区域 - 健康风格设计
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                // 用户头像
                Text("👤")
                    .font(.system(size: 50))
                    .frame(width: 60, height: 60)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(UIColor.systemGray5), lineWidth: 1))
                    .shadow(color: Color(UIColor.label).opacity(0.05), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 用户名
                    Text(userInfo)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // 标签
                    HStack(spacing: 6) {
                        Text("#自律")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.systemBlue).opacity(0.1))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .cornerRadius(12)
                        
                        Text("#高效")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.systemBlue).opacity(0.1))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .cornerRadius(12)
                        
                        Text("#成长")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.systemBlue).opacity(0.1))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // 编辑按钮
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.headline)
                }
            }
            
            // 用户描述
            Text("热爱生活，追求自我提升的普通人")
                .font(.footnote)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.top, 4)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 资产区域 - 健康风格设计
    private var assetSection: some View {
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
                    Text("\(assets.现金 + assets.其他 - assets.负债)")
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
                    Text("\(assets.现金)W")
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
                    Text("\(assets.负债)W")
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
                    Text("\(assets.其他)W")
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
    
    // 目标区域 - 扁平化设计
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🎯")
                        .font(.title3)
                    Text("近期目标")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 目标总数 - 可点击切换到目标标签页
                Button(action: {
                    // 切换到目标标签页（索引为1）
                    selectedTab = 1
                }) {
                    Text("\(goals.count)个目标")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .buttonStyle(PlainButtonStyle())
                
                // 详情按钮 - 可点击切换到目标标签页
                Button(action: {
                    // 切换到目标标签页（索引为1）
                    selectedTab = 1
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            if goals.isEmpty {
                // 空状态
                VStack(spacing: 8) {
                    Text("暂无目标")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Button(action: {
                        // 切换到目标标签页（索引为1）
                        selectedTab = 1
                    }) {
                        Text("去添加目标")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
            } else {
                // 目标列表 - 水平滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(goals.prefix(5)) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    // 目标名称
                                    Text(goal.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .foregroundColor(Color(UIColor.label))
                                    
                                    // 进度条
                                    ZStack(alignment: .leading) {
                                        // 背景
                                        RoundedRectangle(cornerRadius: 3)
                                            .frame(height: 5)
                                            .foregroundColor(Color(UIColor.systemGray5))
                                        
                                        // 进度
                                        RoundedRectangle(cornerRadius: 3)
                                            .frame(width: CGFloat(goal.progress) * 120, height: 5)
                                            .foregroundColor(Color(UIColor.systemBlue))
                                    }
                                    
                                    // 进度文本
                                    Text("\(Int(goal.progress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                                .frame(width: 150)
                                .padding(10)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
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
    
    // 心情区域 - 扁平化设计
    var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("😊")
                        .font(.title3)
                    Text("心情")
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
            
            // 心情图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(moods, id: \.self) { mood in
                        Text(mood)
                            .font(.title2)
                            .frame(width: 42, height: 42)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(height: 60) // 固定高度
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 成就展示区域 - 扁平化设计
    var achievementSection: some View {
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
                        Text(achievement)
                            .font(.title2)
                            .frame(width: 42, height: 42)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(height: 60) // 固定高度
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 待改进区域 - 扁平化设计
    var improvementSection: some View {
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
                        Text(improvement)
                            .font(.title2)
                            .frame(width: 42, height: 42)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(height: 60) // 固定高度
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 最近焦虑区域 - 扁平化设计
    var anxietySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("😰")
                        .font(.title3)
                    Text("最近焦虑")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            // 焦虑列表
            VStack(alignment: .leading, spacing: 8) {
                ForEach(anxieties, id: \.self) { anxiety in
                    HStack(spacing: 8) {
                        // 焦虑图标
                        Text("⚠️")
                            .font(.body)
                        
                        // 焦虑内容
                        Text(anxiety)
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
