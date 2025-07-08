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
    
    // 用户信息
    private let userInfo = "张三"
    
    // 资产信息
    private let assets = (现金: 10, 负债: 5, 其他: 8)
    
    // 目标信息
    private let goals = ["减肥10斤", "学习Swift", "完成项目"]
    private let goalProgress: [Double] = [0.7, 0.5, 0.3]
    
    // 心情记录
    private let moods = ["😊", "😢", "😡", "😴", "🤔", "😎"]
    
    // 成就图标
    private let achievements = ["🏆", "🥇", "🥈", "🥉", "🎖️"]
    
    // 缺点/待改进项
    private let weakPoints = ["🍔", "🛌", "📱"]
    
    // 最近焦虑
    private let anxieties = ["工作压力大", "睡眠不足", "缺乏锻炼"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部标题
                HStack {
                    Text("个人概览")
                        .font(.largeTitle)
                        .fontWeight(.bold)
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
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                
                // 心情记录和成就展示 - 放在同一行
                HStack(spacing: 12) {
                    // 心情记录 - 独立卡片
                    moodSection
                        .padding(16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                    
                    // 成就展示 - 独立卡片
                    achievementSection
                        .padding(16)
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
                weakPointsSection
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                
                // 最近焦虑 - 独立卡片
                anxietySection
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
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
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 用户名
                    Text(userInfo)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // 标签
                    HStack(spacing: 6) {
                        Text("#自律")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.systemBlue).opacity(0.1))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .cornerRadius(12)
                        
                        Text("#高效")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.systemBlue).opacity(0.1))
                            .foregroundColor(Color(UIColor.systemBlue))
                            .cornerRadius(12)
                        
                        Text("#成长")
                            .font(.caption)
                            .fontWeight(.medium)
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
                        .foregroundColor(Color(.systemBlue))
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
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
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
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 总资产
                HStack(spacing: 2) {
                    Text("\(assets.现金 + assets.其他 - assets.负债)")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.systemBlue))
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
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(.systemGray5))
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
                        .foregroundColor(Color(UIColor.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(.systemGray5))
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
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 目标区域 - 健康风格设计
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🎯")
                        .font(.title3)
                    Text("近期目标")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 目标总数
                Text("共\(goals.count)个目标")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            // 目标列表
            VStack(spacing: 12) {
                ForEach(0..<goals.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            // 目标名称
                            Text(goals[index])
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                            
                            // 进度百分比
                            Text("\(Int(goalProgress[index] * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(index % 4 == 0 ? Color(UIColor.systemGreen) : 
                                               index % 4 == 1 ? Color(UIColor.systemRed) : 
                                               index % 4 == 2 ? Color(UIColor.systemBlue) : 
                                               Color(UIColor.systemOrange))
                        }
                        
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: geometry.size.width, height: 6)
                                    .foregroundColor(Color(UIColor.systemGray5))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: min(CGFloat(goalProgress[index]) * geometry.size.width, geometry.size.width), height: 6)
                                    .foregroundColor(index % 4 == 0 ? Color(UIColor.systemGreen) : 
                                                    index % 4 == 1 ? Color(UIColor.systemRed) : 
                                                    index % 4 == 2 ? Color(UIColor.systemBlue) : 
                                                    Color(UIColor.systemOrange))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 心情区域 - 健康风格设计
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("😊")
                        .font(.title3)
                    Text("心情")
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
            
            // 心情图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(moods, id: \.self) { mood in
                        Text(mood)
                            .font(.title2)
                            .frame(width: 46, height: 46)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 6)
            }
            .frame(height: 70) // 固定高度
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 成就区域 - 健康风格设计
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🏆")
                        .font(.title3)
                    Text("成就")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 成就图标 - 横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(achievements, id: \.self) { achievement in
                        Text(achievement)
                            .font(.title2)
                            .frame(width: 46, height: 46)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 6)
            }
            .frame(height: 70) // 固定高度
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 待改进区域 - 健康风格设计
    private var weakPointsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🔄")
                        .font(.title3)
                    Text("待改进")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 缺点图标
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(weakPoints, id: \.self) { point in
                        VStack(spacing: 6) {
                            Text(point)
                                .font(.title3)
                                .frame(width: 54, height: 54)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            
                            Text("待改进")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    // 焦虑区域 - 健康风格设计
    private var anxietySection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 焦虑列表
            VStack(spacing: 12) {
                ForEach(anxieties, id: \.self) { anxiety in
                    HStack {
                        Text(anxiety)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Spacer()
                        
                        Text("今天")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
}
